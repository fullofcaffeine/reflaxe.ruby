# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "shellwords"
require "stringio"
require "tmpdir"
require "hxruby/development_watcher"

class DevelopmentWatcherTest < Minitest::Test
  LIB_ROOT = File.expand_path("../lib", __dir__)

  def setup
    @root = Dir.mktmpdir("hxruby-development-watcher.")
    write("server_src/ServerMain.hx", "class ServerMain {}\n")
    write("client_src/ClientMain.hx", "class ClientMain {}\n")
    write("shared/Shared.hx", "class Shared {}\n")
    write("vendor/local/src/Local.hx", "class Local {}\n")
    write("shared.hxml", "-cp shared\n")
    write("build.hxml", "-cp server_src # app server\nshared.hxml\n-lib local:dev\n-main ServerMain\n")
    write("build-client.hxml", "-cp=client_src\nshared.hxml\n-main ClientMain\n")
    write(".haxerc", "{\"version\":\"4.3.7\"}\n")
    write("haxe_libraries/local.hxml", "-cp ${LOCAL_SOURCE}\n-lib reflaxe\n")
    write("haxe_libraries/reflaxe.hxml", "-cp vendor/reflaxe/src\n")
    write("haxe_libraries/client-only.hxml", "-cp client_only_src\n")
    @environment = ENV.to_h.merge("LOCAL_SOURCE" => File.join(@root, "vendor", "local", "src"))
    @events = []
    @out = StringIO.new
    @err = StringIO.new
  end

  def teardown
    FileUtils.remove_entry(@root) if File.exist?(@root)
  end

  def test_discovers_hxml_includes_classpaths_resolver_inputs_and_explicit_paths
    missing_extra = File.join(@root, "future_shared")
    target = build_target(:server, "build.hxml", extra_paths: [missing_extra])

    expected = [
      ".haxerc",
      "build.hxml",
      "haxe_libraries/local.hxml",
      "haxe_libraries/reflaxe.hxml",
      "server_src",
      "shared",
      "shared.hxml",
      "vendor/local/src",
      "vendor/reflaxe/src",
      "future_shared",
    ].map { |path| File.join(@root, path) }
    expected.each { |path| assert_includes(target.paths, path) }
    refute_includes(target.paths, File.join(@root, "haxe_libraries", "client-only.hxml"))
  end

  def test_initial_build_is_once_and_only_changed_targets_rebuild_after_debounce
    watcher = build_watcher
    watcher.prime!
    assert_equal(%i[server client], @events)

    assert_empty(watcher.poll_once(now: 0.0))
    assert_equal(%i[server client], @events)

    write("server_src/ServerMain.hx", "class ServerMain { static var revision = 1; }\n")
    assert_empty(watcher.poll_once(now: 1.0))
    assert_empty(watcher.poll_once(now: 1.05))
    assert_equal([:server], watcher.poll_once(now: 1.11))
    assert_equal(%i[server client server], @events)

    write("client_src/ClientMain.hx", "class ClientMain { static var revision = 1; }\n")
    assert_empty(watcher.poll_once(now: 1.5))
    assert_equal([:client], watcher.poll_once(now: 1.61))
    assert_equal(%i[server client server client], @events)
  end

  def test_shared_edit_burst_coalesces_both_targets_once
    watcher = build_watcher
    watcher.prime!
    @events.clear

    write("shared/Shared.hx", "class Shared { static var revision = 1; }\n")
    assert_empty(watcher.poll_once(now: 2.0))
    write("shared/Shared.hx", "class Shared { static var revision = 22; }\n")
    assert_empty(watcher.poll_once(now: 2.05))
    assert_empty(watcher.poll_once(now: 2.11))
    assert_equal(%i[server client], watcher.poll_once(now: 2.16))
    assert_equal(%i[server client], @events)
  end

  def test_rebuild_failure_is_reported_and_a_later_edit_recovers
    client_attempts = 0
    server = build_target(:server, "build.hxml") { @events << :server }
    client = build_target(:client, "build-client.hxml") do
      client_attempts += 1
      @events << :client
      raise "typed client compile failed" if client_attempts == 2
    end
    watcher = watcher_for([server, client])
    watcher.prime!

    write("client_src/ClientMain.hx", "class ClientMain { static var broken = true; }\n")
    watcher.poll_once(now: 3.0)
    assert_equal([:client], watcher.poll_once(now: 3.11))
    assert_includes(@err.string, "client rebuild failed: typed client compile failed")

    write("client_src/ClientMain.hx", "class ClientMain { static var fixed = true; }\n")
    watcher.poll_once(now: 4.0)
    assert_equal([:client], watcher.poll_once(now: 4.11))
    assert_equal(3, client_attempts)
  end

  def test_coordinated_runner_can_skip_duplicate_initial_build
    watcher = build_watcher
    watcher.prime!(initial_compile: false)
    assert_empty(@events)

    write("server_src/ServerMain.hx", "class ServerMain { static var afterStart = true; }\n")
    watcher.poll_once(now: 5.0)
    assert_equal([:server], watcher.poll_once(now: 5.11))
    assert_equal([:server], @events)
  end

  def test_non_haxe_files_under_classpaths_do_not_trigger_rebuilds
    watcher = build_watcher
    watcher.prime!
    @events.clear

    write("server_src/notes.md", "not a compiler input\n")
    assert_empty(watcher.poll_once(now: 6.0))
    assert_empty(@events)
  end

  def test_missing_build_and_invalid_timing_fail_closed
    error = assert_raises(HXRuby::DevelopmentWatcher::Error) do
      build_target(:missing, "missing.hxml")
    end
    assert_includes(error.message, "Haxe build file does not exist")

    assert_raises(HXRuby::DevelopmentWatcher::Error) do
      HXRuby::DevelopmentWatcher.new(targets: [build_target(:server, "build.hxml")], interval: 0)
    end
    assert_raises(HXRuby::DevelopmentWatcher::Error) do
      HXRuby::DevelopmentWatcher.new(targets: [build_target(:server, "build.hxml")], debounce: -1)
    end
  end

  def test_packaged_rake_task_builds_once_then_stays_idle_until_each_target_changes
    fake_bin = File.join(@root, "fake-bin")
    task_log = File.join(@root, "haxe.log")
    process_log = File.join(@root, "watcher.log")
    FileUtils.mkdir_p(fake_bin)
    write("Rakefile", "require \"hxruby/tasks\"\n")
    write("fake-bin/haxe", <<~RUBY)
      #!/usr/bin/env ruby
      File.open(ENV.fetch("HXRUBY_TEST_WATCH_LOG"), "a") { |file| file.puts(ARGV.join(" ")) }
      if ARGV.first == "build-client.hxml" && File.exist?("fail-client")
        warn "synthetic client failure"
        exit 2
      end
    RUBY
    FileUtils.chmod(0o755, File.join(fake_bin, "haxe"))
    rake = Gem.bin_path("rake", "rake")
    environment = {
      "HXRUBY_TEST_WATCH_LOG" => task_log,
      "HXRUBY_WATCH_INTERVAL" => "0.05",
      "HXRUBY_WATCH_DEBOUNCE" => "0.02",
      "PATH" => [fake_bin, ENV.fetch("PATH", nil)].compact.join(File::PATH_SEPARATOR),
      "RUBYLIB" => [LIB_ROOT, ENV.fetch("RUBYLIB", nil)].compact.join(File::PATH_SEPARATOR),
    }
    pid = Process.spawn(environment, RbConfig.ruby, rake, "hxruby:watch:all", chdir: @root, out: process_log, err: process_log)

    wait_until("initial server/client watcher builds") { log_lines(task_log).length >= 2 }
    assert_equal(["build.hxml", "build-client.hxml"], log_lines(task_log))
    sleep 0.2
    assert_equal(2, log_lines(task_log).length, "unchanged polling unexpectedly recompiled")

    write("server_src/ServerMain.hx", "class ServerMain { static var taskRevision = 1; }\n")
    wait_until("server-only watcher rebuild") { log_lines(task_log).length >= 3 }
    assert_equal("build.hxml", log_lines(task_log)[2])

    write("fail-client", "1\n")
    write("client_src/ClientMain.hx", "class ClientMain { static var taskRevision = 1; }\n")
    wait_until("client-only watcher rebuild") { log_lines(task_log).length >= 4 }
    assert_equal("build-client.hxml", log_lines(task_log)[3])
    wait_until("recoverable task failure output") do
      File.file?(process_log) && File.read(process_log).include?("client rebuild failed")
    end
    Process.kill(0, pid)

    FileUtils.rm_f(File.join(@root, "fail-client"))
    write("client_src/ClientMain.hx", "class ClientMain { static var taskRevision = 22; }\n")
    wait_until("client watcher recovery") { log_lines(task_log).length >= 5 }
    assert_equal("build-client.hxml", log_lines(task_log)[4])
  ensure
    if pid
      begin
        Process.kill("INT", pid)
        Process.wait(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end
    end
  end

  def test_hxruby_dev_builds_both_targets_once_before_starting_rails_and_child_watcher
    fake_bin = File.join(@root, "fake-bin")
    rails_bin = File.join(@root, "bin")
    task_log = File.join(@root, "dev-haxe.log")
    FileUtils.mkdir_p(fake_bin)
    FileUtils.mkdir_p(rails_bin)
    write("Rakefile", "require \"hxruby/tasks\"\n")
    write("fake-bin/haxe", <<~RUBY)
      #!/usr/bin/env ruby
      File.open(ENV.fetch("HXRUBY_TEST_WATCH_LOG"), "a") { |file| file.puts(ARGV.join(" ")) }
    RUBY
    write("bin/rails", <<~RUBY)
      #!/usr/bin/env ruby
      exit 0
    RUBY
    FileUtils.chmod(0o755, File.join(fake_bin, "haxe"))
    FileUtils.chmod(0o755, File.join(rails_bin, "rails"))
    rake = Gem.bin_path("rake", "rake")
    environment = {
      "HXRUBY_TEST_WATCH_LOG" => task_log,
      "PATH" => [fake_bin, ENV.fetch("PATH", nil)].compact.join(File::PATH_SEPARATOR),
      "RAKE" => Shellwords.join([RbConfig.ruby, rake]),
      "RUBYLIB" => [LIB_ROOT, ENV.fetch("RUBYLIB", nil)].compact.join(File::PATH_SEPARATOR),
    }

    stdout, stderr, status = Open3.capture3(environment, RbConfig.ruby, rake, "hxruby:dev", chdir: @root)
    assert(status.success?, "hxruby:dev failed:\n#{stdout}\n#{stderr}")
    assert_equal(["build.hxml", "build-client.hxml"], log_lines(task_log))
    assert_includes(stdout, "HXRUBY_WATCH_SKIP_INITIAL=1")
    assert_includes(stdout, "hxruby:watch:all")
  end

  private

  def build_watcher
    watcher_for([
      build_target(:server, "build.hxml"),
      build_target(:client, "build-client.hxml"),
    ])
  end

  def watcher_for(targets)
    HXRuby::DevelopmentWatcher.new(targets: targets, interval: 0.01, debounce: 0.1, out: @out, err: @err)
  end

  def build_target(name, hxml, extra_paths: [], &compile)
    callback = compile || -> { @events << name }
    HXRuby::DevelopmentWatcher.target(
      name: name,
      hxml: hxml,
      root: @root,
      extra_paths: extra_paths,
      environment: @environment,
      compile: callback
    )
  end

  def write(relative_path, content)
    path = File.join(@root, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def log_lines(path)
    File.file?(path) ? File.readlines(path, chomp: true) : []
  end

  def wait_until(label, timeout: 5)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until yield
      flunk("timed out waiting for #{label}") if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.02
    end
  end
end
