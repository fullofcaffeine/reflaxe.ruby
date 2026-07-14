# frozen_string_literal: true

require "minitest/autorun"
require "hxruby/support_matrix"

class SupportMatrixTest < Minitest::Test
  def test_packaged_schema_and_current_runtime_contract
    assert_equal 1, HXRuby::SupportMatrix::DATA.fetch("schemaVersion")
    assert_equal ["3.3", "3.4", "4.0"], HXRuby::SupportMatrix.supported_ruby_branches
    assert_equal "7.2.3.1", HXRuby::SupportMatrix::DATA.dig("railsHx", "verifiedRuntime", "railsVersion")
    refute HXRuby::SupportMatrix::DATA.dig("railsHx", "plannedRuntime", "supported")
  end

  def test_ruby_diagnostics_accept_only_supported_mri_branches
    assert_nil HXRuby::SupportMatrix.ruby_error("3.3.11", "ruby")
    assert_nil HXRuby::SupportMatrix.ruby_error("3.4.10", "ruby")
    assert_nil HXRuby::SupportMatrix.ruby_error("4.0.5", "ruby")

    eol = HXRuby::SupportMatrix.ruby_error("3.2.11", "ruby")
    assert_includes eol, "outside the supported MRI branches"
    assert_includes eol, "reached end of life"
    assert_includes HXRuby::SupportMatrix.ruby_error("4.1.0", "ruby"), "outside the supported MRI branches"
    assert_includes HXRuby::SupportMatrix.ruby_error("3.4.10", "jruby"), "supports MRI Ruby"
  end

  def test_gem_installation_rejects_known_unsupported_ruby_versions
    specification = Gem::Specification.load(File.expand_path("../hxruby.gemspec", __dir__))
    refute specification.required_ruby_version.satisfied_by?(Gem::Version.new("3.2.11"))
    assert specification.required_ruby_version.satisfied_by?(Gem::Version.new("3.3.11"))
    assert specification.required_ruby_version.satisfied_by?(Gem::Version.new("3.4.10"))
    assert specification.required_ruby_version.satisfied_by?(Gem::Version.new("4.0.5"))
    refute specification.required_ruby_version.satisfied_by?(Gem::Version.new("4.1.0"))
  end

  def test_node_diagnostics_enforce_the_declared_major_range
    assert_nil HXRuby::SupportMatrix.node_error("v22.14.0")
    assert_nil HXRuby::SupportMatrix.node_error("22.23.1")
    assert_includes HXRuby::SupportMatrix.node_error("22.13.1"), ">=22.14.0 <23"
    assert_includes HXRuby::SupportMatrix.node_error("23.0.0"), ">=22.14.0 <23"
    assert_includes HXRuby::SupportMatrix.node_error("unknown"), "could not be parsed"
  end

  def test_haxe_and_rails_diagnostics_match_actual_evidence
    assert_nil HXRuby::SupportMatrix.haxe_error("4.3.7")
    assert_includes HXRuby::SupportMatrix.haxe_error("4.4.0"), "unsupported"
    assert_nil HXRuby::SupportMatrix.rails_error("7.2.3.1")
    assert_includes HXRuby::SupportMatrix.rails_error("8.1.2.1"), "planned but not supported"
  end

  def test_noncanonical_platform_is_reported_as_unverified
    assert_nil HXRuby::SupportMatrix.platform_warning("linux-gnu", "x86_64")
    warning = HXRuby::SupportMatrix.platform_warning("darwin24", "arm64")
    assert_includes warning, "outside the canonical ubuntu-24.04 x86_64 evidence lane"
  end
end
