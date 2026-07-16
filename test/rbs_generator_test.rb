# frozen_string_literal: true

ENV["MT_NO_PLUGINS"] = "1"

require "minitest/autorun"
require "tmpdir"
require "hxruby/rbs"

class RbsGeneratorTest < Minitest::Test
  FIXTURE_ROOT = File.expand_path("fixtures/rbs_generator", __dir__)
  SNAPSHOT = File.expand_path("snapshots/m1/rbs_generator/generated/rbs/FixtureCatalog.hx", __dir__)

  def test_canonical_render_is_independent_of_source_order
    first = render_fixture("catalog.rbs")
    second = render_fixture("catalog_permuted.rbs")

    assert_equal first, second
    assert_equal File.read(SNAPSHOT), first
    assert first.end_with?("\n")
    refute_match(/\r/, first)
  end

  def test_unsupported_shapes_become_review_markers_without_broad_types
    output = render_unsupported("unsupported.rbs")
    assert_equal output, render_unsupported("unsupported_permuted.rbs")

    %w[open_input open_return keyword_shape block_shape overloaded].each do |method|
      assert_includes output, "Review required: skipped #{method}:"
    end
    ["Dynamic", "Any", "untyped", "__ruby__", "cast "].each do |forbidden|
      refute_includes output, forbidden
    end
    refute_match(/line \d+/, output)
  end

  def test_generated_haxe_name_collisions_fail_closed
    Dir.mktmpdir("hxruby-rbs-collision.") do |root|
      File.write(File.join(root, "collision.rbs"), <<~RBS)
        class Collision
          def ready?: () -> bool
          def ready!: () -> bool
        end
      RBS

      error = assert_raises(HXRuby::Rbs::Error) { render_from(root, "collision.rbs", "Collision") }
      assert_includes error.message, "Haxe member collisions: ready"
    end
  end

  def test_strict_source_rejects_malformed_and_unknown_top_level_declarations
    Dir.mktmpdir("hxruby-rbs-malformed.") do |root|
      File.write(File.join(root, "unterminated.rbs"), "class Broken\n  def value: () -> String\n")
      File.write(File.join(root, "unknown.rbs"), "type label = String\n")

      error = assert_raises(HXRuby::Rbs::Error) { render_from(root, "unterminated.rbs", "Broken") }
      assert_includes error.message, "Unterminated RBS declaration"
      error = assert_raises(HXRuby::Rbs::Error) { render_from(root, "unknown.rbs", "Unknown") }
      assert_includes error.message, "Unsupported top-level RBS declaration"
    end
  end

  def test_strict_declaration_headers_and_module_instance_methods_fail_closed
    Dir.mktmpdir("hxruby-rbs-declarations.") do |root|
      File.write(File.join(root, "inherited.rbs"), "class Child < Parent\nend\n")
      File.write(File.join(root, "mixin.rbs"), "module Mixin\n  def value: () -> String\nend\n")

      error = assert_raises(HXRuby::Rbs::Error) { render_from(root, "inherited.rbs", "Child") }
      assert_includes error.message, "Unsupported RBS declaration header"
      error = assert_raises(HXRuby::Rbs::Error) { render_from(root, "mixin.rbs", "Mixin") }
      assert_includes error.message, "modules can generate only self methods"
    end
  end

  def test_checked_source_rejects_missing_traversal_and_symlink_escape
    error = assert_raises(HXRuby::Rbs::Error) { render_from(FIXTURE_ROOT, "missing.rbs", "Missing") }
    assert_includes error.message, "RBS source does not exist"
    error = assert_raises(HXRuby::Rbs::Error) { render_from(FIXTURE_ROOT, "../catalog.rbs", "FixtureCatalog") }
    assert_includes error.message, "safe forward-slash relative path"

    Dir.mktmpdir("hxruby-rbs-root.") do |root|
      Dir.mktmpdir("hxruby-rbs-outside.") do |outside|
        source = File.join(outside, "outside.rbs")
        File.write(source, "class Outside\nend\n")
        File.symlink(source, File.join(root, "escape.rbs"))
        error = assert_raises(HXRuby::Rbs::Error) { render_from(root, "escape.rbs", "Outside") }
        assert_includes error.message, "must resolve to a file inside"
      end
    end
  end

  private

  def render_unsupported(input)
    HXRuby::Rbs::ExternGenerator.new(
      root: FIXTURE_ROOT,
      input: input,
      constant_name: "UnsupportedCatalog",
      package_name: "generated.rbs",
      source_label: "unsupported.rbs"
    ).render
  end

  def render_fixture(input)
    HXRuby::Rbs::ExternGenerator.new(
      root: FIXTURE_ROOT,
      input: input,
      constant_name: "FixtureCatalog",
      package_name: "generated.rbs",
      require_path: "fixture_catalog",
      source_label: "catalog.rbs"
    ).render
  end

  def render_from(root, input, constant)
    HXRuby::Rbs::ExternGenerator.new(
      root: root,
      input: input,
      constant_name: constant,
      package_name: "generated.rbs"
    ).render
  end
end
