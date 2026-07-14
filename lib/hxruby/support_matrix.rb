# frozen_string_literal: true

require "json"
require "rbconfig"
require "rubygems"

module HXRuby
  # Reads the packaged compatibility contract and produces actionable doctor
  # diagnostics without turning unverified environments into hidden support.
  module SupportMatrix
    PATH = File.expand_path("support_matrix.json", __dir__)
    DATA = JSON.parse(File.read(PATH)).freeze

    module_function

    def ruby_error(version = RUBY_VERSION)
      minimum = DATA.dig("ruby", "minimumVersion")
      return nil if Gem::Version.new(version) >= Gem::Version.new(minimum)

      branch = version_branch(version)
      known = DATA.fetch("ruby").fetch("knownUnsupported").find { |entry| entry.fetch("version") == branch }
      detail = known ? " #{known.fetch("reason")}" : ""
      "Ruby #{version} is below the required minimum #{minimum}.#{detail}"
    rescue ArgumentError
      "Ruby version #{version.inspect} could not be parsed; expected Ruby >= #{minimum}"
    end

    def ruby_warning(version = RUBY_VERSION, engine = RUBY_ENGINE)
      branch = version_branch(version)
      return nil if engine == DATA.dig("ruby", "engine") && supported_ruby_branches.include?(branch)

      "Ruby #{version} (#{engine}) is outside the tested MRI branches #{supported_ruby_branches.join(", ")}; it may work but is unverified"
    end

    def node_error(version)
      normalized = version.to_s.strip.delete_prefix("v")
      minimum = DATA.dig("node", "minimumVersion")
      maximum = DATA.dig("node", "maximumExclusiveVersion")
      return nil if version_at_least_and_below?(normalized, minimum, maximum)

      "Node.js #{normalized} is outside the supported range #{DATA.dig("node", "supportedRange")}"
    rescue ArgumentError
      "Node.js version #{version.inspect} could not be parsed; expected #{DATA.dig("node", "supportedRange")}"
    end

    def haxe_error(version)
      normalized = version.to_s.strip
      supported = DATA.dig("haxe", "supportedVersions")
      return nil if supported.include?(normalized)

      "Haxe #{normalized} is unsupported; install Haxe #{supported.join(" or ")}"
    end

    def rails_warning(version)
      normalized = version.to_s.strip
      verified_line = DATA.dig("railsHx", "verifiedRuntime", "railsLine")
      verified = DATA.dig("railsHx", "verifiedRuntime", "railsVersion")
      return nil if version_branch(normalized) == verified_line

      "Rails #{normalized} is outside the verified RailsHx beta line (Rails #{verified_line}, exercised at #{verified}); it may work but is unverified"
    end

    def platform_warning(host_os = RbConfig::CONFIG.fetch("host_os"), host_cpu = RbConfig::CONFIG.fetch("host_cpu"))
      canonical = DATA.fetch("canonicalPlatform")
      os_matches = host_os.downcase.include?(canonical.fetch("os"))
      cpu_matches = ["x86_64", "amd64"].include?(host_cpu.downcase)
      return nil if os_matches && cpu_matches

      "#{host_cpu}-#{host_os} is outside the canonical #{canonical.fetch("runner")} #{canonical.fetch("architecture")} evidence lane"
    end

    def supported_ruby_branches
      DATA.dig("ruby", "branches").map { |entry| entry.fetch("version") }
    end

    def version_branch(version)
      components = version.to_s.split(".")
      components.first(2).join(".")
    end

    def version_at_least_and_below?(version, minimum, maximum_exclusive)
      candidate = Gem::Version.new(version)
      candidate >= Gem::Version.new(minimum) && candidate < Gem::Version.new(maximum_exclusive)
    end
    private_class_method :version_branch, :version_at_least_and_below?
  end
end
