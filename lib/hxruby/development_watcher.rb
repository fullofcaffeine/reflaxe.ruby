# frozen_string_literal: true

require "digest"
require "pathname"
require "shellwords"

module HXRuby
  # Coordinates change-aware Haxe rebuilds for RailsHx development tasks.
  #
  # One-shot, CI, and production compiles remain direct `haxe build.hxml`
  # invocations. This watcher owns only the long-running developer loop: it
  # discovers checked HXML/classpath inputs, snapshots relevant files, debounces
  # edit bursts, and rebuilds each affected target at most once per burst.
  class DevelopmentWatcher
    class Error < StandardError; end

    Target = Struct.new(:name, :hxml, :paths, :compile, keyword_init: true)

    WATCHED_EXTENSIONS = %w[.hx .hhx .hxml .json].freeze
    IGNORED_DIRECTORIES = %w[.git .generated build log node_modules tmp].freeze
    DEFAULT_INTERVAL = 0.2
    DEFAULT_DEBOUNCE = 0.1

    class << self
      # Builds one validated watch target from its real Haxe build contract.
      def target(name:, hxml:, compile:, root: Dir.pwd, extra_paths: [], environment: ENV.to_h)
        project_root = File.expand_path(root)
        build_file = File.expand_path(hxml, project_root)
        raise Error, "Haxe build file does not exist: #{relative_label(build_file, project_root)}" unless File.file?(build_file)
        raise Error, "watch target #{name.inspect} needs a compile callback" unless compile.respond_to?(:call)

        paths = discover_build_inputs(build_file, root: project_root, environment: environment)
        paths.concat(Array(extra_paths).map { |path| File.expand_path(path, project_root) })
        Target.new(name: name.to_sym, hxml: build_file, paths: paths.uniq.sort.freeze, compile: compile).freeze
      end

      # Returns HXML files, classpaths, and local Haxe resolver configuration.
      def discover_build_inputs(hxml, root:, environment: ENV.to_h)
        project_root = File.expand_path(root)
        queue = [File.expand_path(hxml, project_root)]
        resolver_root = File.join(project_root, "haxe_libraries")
        paths = [File.join(project_root, ".haxerc")]
        visited = {}

        until queue.empty?
          build_file = queue.shift
          next if visited[build_file]

          visited[build_file] = true
          paths << build_file
          next unless File.file?(build_file)

          tokens = hxml_tokens(File.read(build_file))
          index = 0
          while index < tokens.length
            token = tokens[index]
            if %w[-cp --class-path].include?(token)
              index += 1
              add_input_path(paths, tokens[index], project_root, environment)
            elsif (match = token.match(/\A(?:-cp|--class-path)=(.+)\z/))
              add_input_path(paths, match[1], project_root, environment)
            elsif %w[-lib -L].include?(token)
              index += 1
              add_library_resolver(queue, tokens[index], resolver_root)
            elsif (match = token.match(/\A(?:-lib|-L)=(.+)\z/))
              add_library_resolver(queue, match[1], resolver_root)
            elsif token.end_with?(".hxml") && !token.start_with?("-")
              included = expanded_input_path(token, project_root, environment)
              queue << included if included
            end
            index += 1
          end
        end

        paths.uniq.sort
      end

      private

      def hxml_tokens(content)
        content.each_line.flat_map do |line|
          stripped = line.strip
          next [] if stripped.empty? || stripped.start_with?("#")

          tokens = Shellwords.split(line)
          comment = tokens.index { |token| token.start_with?("#") }
          comment ? tokens.take(comment) : tokens
        rescue ArgumentError => error
          raise Error, "invalid HXML shell quoting: #{error.message}"
        end
      end

      def add_input_path(paths, raw_path, root, environment)
        path = expanded_input_path(raw_path, root, environment)
        paths << path if path
      end

      # Lix's scoped resolver maps `-lib foo[:version]` to
      # `haxe_libraries/foo.hxml`. Following only referenced resolvers keeps a
      # client-only library from making an unrelated server target rebuild.
      # Missing resolver files remain explicit snapshot entries, so creating a
      # checked local resolver later still triggers the target.
      def add_library_resolver(queue, raw_library, resolver_root)
        name = raw_library.to_s.split(":", 2).first
        return if name.empty? || name.include?("\0") || name.include?("/") || name.include?("\\") || name == "." || name == ".."

        queue << File.join(resolver_root, "#{name}.hxml")
      end

      def expanded_input_path(raw_path, root, environment)
        return nil if raw_path.nil? || raw_path.empty? || raw_path.start_with?("haxelib:")

        unresolved = false
        expanded = raw_path.gsub(/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/) do
          value = environment[Regexp.last_match(1)]
          unresolved = true if value.nil? || value.empty?
          value.to_s
        end
        return nil if unresolved || expanded.include?("\0")

        File.expand_path(expanded, root)
      end

      def relative_label(path, root)
        Pathname.new(path).relative_path_from(Pathname.new(root)).to_s
      rescue ArgumentError
        path
      end
    end

    def initialize(targets:, interval: DEFAULT_INTERVAL, debounce: DEFAULT_DEBOUNCE, out: $stdout, err: $stderr,
      clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }, sleeper: ->(seconds) { sleep(seconds) })
      @targets = Array(targets)
      raise Error, "at least one Haxe watch target is required" if @targets.empty?

      names = @targets.map(&:name)
      raise Error, "Haxe watch target names must be unique" if names.uniq.length != names.length

      @interval = positive_number(interval, "HXRUBY_WATCH_INTERVAL")
      @debounce = non_negative_number(debounce, "HXRUBY_WATCH_DEBOUNCE")
      @out = out
      @err = err
      @clock = clock
      @sleeper = sleeper
      @snapshots = {}
      @pending = {}
      @deadline = nil
      @primed = false
    end

    # Starts the blocking developer loop. Initial compilation is skipped only
    # when an owning runner has already built both targets in the same process
    # workflow, as `hxruby:dev` does before Rails starts.
    def run(initial_compile: true)
      prime!(initial_compile: initial_compile)
      @out.puts("[hxruby:watch] Watching #{target_names.join(', ')} inputs every #{format_seconds(@interval)}; debounce #{format_seconds(@debounce)}.")
      loop do
        @sleeper.call(@interval)
        poll_once
      end
    rescue Interrupt
      @out.puts("\n[hxruby:watch] Stopped.")
    end

    # Establishes the post-build baseline. Kept separate so the coordinated
    # Rails runner can prove there is no duplicate initial compilation.
    def prime!(initial_compile: true)
      compile_targets(@targets, fail_fast: true) if initial_compile
      @targets.each { |target| @snapshots[target.name] = snapshot(target.paths) }
      @primed = true
      self
    end

    # Performs one deterministic detection/debounce step. Returning attempted
    # target names makes the scheduler executable-testable without sleeps.
    def poll_once(now: @clock.call)
      raise Error, "watcher must be primed before polling" unless @primed

      changed = []
      @targets.each do |target|
        current = snapshot(target.paths)
        next if current == @snapshots[target.name]

        @snapshots[target.name] = current
        @pending[target.name] = target
        changed << target.name
      end
      unless changed.empty?
        @deadline = now + @debounce
        @out.puts("[hxruby:watch] Change detected for #{changed.join(', ')}; waiting for the edit burst to settle.")
      end

      return [] if @pending.empty? || now < @deadline

      targets = @targets.select { |target| @pending.key?(target.name) }
      @pending.clear
      @deadline = nil
      compile_targets(targets, fail_fast: false)
      targets.map(&:name)
    end

    private

    def compile_targets(targets, fail_fast:)
      targets.each do |target|
        @out.puts("[hxruby:watch] Building #{target.name} (#{display_path(target.hxml)})...")
        target.compile.call
        @out.puts("[hxruby:watch] #{target.name} build ready.")
      rescue StandardError => error
        raise if fail_fast

        @err.puts("[hxruby:watch] #{target.name} rebuild failed: #{error.message}")
      end
    end

    def snapshot(paths)
      entries = []
      seen_directories = {}
      paths.each { |path| collect_snapshot(path, entries, seen_directories, explicit: true) }
      Digest::SHA256.hexdigest(entries.sort.join("\0"))
    end

    def collect_snapshot(path, entries, seen_directories, explicit:)
      stat = File.stat(path)
      if stat.directory?
        real = File.realpath(path)
        return if seen_directories[real]

        seen_directories[real] = true
        Dir.children(path).sort.each do |entry|
          next if IGNORED_DIRECTORIES.include?(entry)

          collect_snapshot(File.join(path, entry), entries, seen_directories, explicit: false)
        end
      elsif explicit || WATCHED_EXTENSIONS.include?(File.extname(path))
        entries << [path, stat.size, stat.mtime.to_i, stat.mtime.nsec, stat.ino].join(":")
      end
    rescue Errno::ENOENT, Errno::ENOTDIR
      entries << "missing:#{path}" if explicit
    rescue Errno::EACCES => error
      entries << "unreadable:#{path}:#{error.class}"
    end

    def target_names
      @targets.map(&:name)
    end

    def display_path(path)
      Pathname.new(path).relative_path_from(Pathname.new(Dir.pwd)).to_s
    rescue ArgumentError
      path
    end

    def positive_number(value, label)
      number = Float(value)
      raise Error, "#{label} must be greater than zero" unless number.positive? && number.finite?

      number
    rescue ArgumentError, TypeError
      raise Error, "#{label} must be a finite number greater than zero"
    end

    def non_negative_number(value, label)
      number = Float(value)
      raise Error, "#{label} must be zero or greater" if number.negative? || !number.finite?

      number
    rescue ArgumentError, TypeError
      raise Error, "#{label} must be a finite number zero or greater"
    end

    def format_seconds(value)
      "#{format('%.3f', value).sub(/0+\z/, '').sub(/\.\z/, '')}s"
    end
  end
end
