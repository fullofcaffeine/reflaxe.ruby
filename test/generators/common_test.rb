# frozen_string_literal: true

ENV["MT_NO_PLUGINS"] = "1"

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../../lib/hxruby/generators/common"

original_verbose = $VERBOSE
begin
  $VERBOSE = nil
  require_relative "../../lib/hxruby/tasks"
ensure
  $VERBOSE = original_verbose
end

class HXRubyGeneratorCommonTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir("hxruby-generator-common.")
    @root = File.join(@tmp, "app")
    FileUtils.mkdir_p(@root)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_regular_output_remains_manifest_owned_and_cleanable
    output = File.join(@root, "generated", "owned.rb")

    HXRuby::Generators::Common.write_file(
      output,
      "class Owned; end\n",
      root: @root,
      kind: "ruby",
      source: "test"
    )

    assert_equal "class Owned; end\n", File.read(output)
    assert HXRuby::Generators::Common.owned_file?(output, @root)
    HXRuby::Generators::Common.clean_owned_outputs(@root)
    refute_path_exists output
  end

  def test_rootless_writer_keeps_parent_creation_behavior
    output = File.join(@tmp, "rootless", "nested", "output.rb")

    HXRuby::Generators::Common.write_file(output, "class Rootless; end\n")

    assert_equal "class Rootless; end\n", File.read(output)
  end

  def test_manifest_owned_output_symlink_cannot_escape_root
    outside = write_outside("outside.rb", "before\n")
    output = symlink_output("generated/owned.rb", outside)
    write_manifest("generated/owned.rb")

    error = assert_raises(HXRuby::Generators::Error) do
      HXRuby::Generators::Common.write_file(output, "after\n", root: @root, kind: "ruby", source: "test")
    end

    assert_match(/must not be a symlink|resolves outside/, error.message)
    assert_equal "before\n", File.read(outside)
  end

  def test_force_does_not_bypass_output_symlink_containment
    outside = write_outside("forced.rb", "before\n")
    output = symlink_output("generated/forced.rb", outside)

    assert_raises(HXRuby::Generators::Error) do
      HXRuby::Generators::Common.write_file(output, "after\n", force: true, root: @root, kind: "ruby", source: "test")
    end

    assert_equal "before\n", File.read(outside)
  end

  def test_symlinked_parent_cannot_redirect_new_output
    outside_dir = File.join(@tmp, "outside")
    FileUtils.mkdir_p(outside_dir)
    File.symlink(outside_dir, File.join(@root, "generated"))
    output = File.join(@root, "generated", "new.rb")

    error = assert_raises(HXRuby::Generators::Error) do
      HXRuby::Generators::Common.write_file(output, "after\n", force: true, root: @root, kind: "ruby", source: "test")
    end

    assert_match(/resolves outside/, error.message)
    refute_path_exists File.join(outside_dir, "new.rb")
  end

  def test_manifest_symlink_cannot_redirect_manifest_write
    outside = write_outside("manifest.json", "outside manifest\n")
    FileUtils.mkdir_p(File.join(@root, ".railshx"))
    File.symlink(outside, File.join(@root, ".railshx", "manifest.json"))
    output = File.join(@root, "generated", "owned.rb")

    assert_raises(HXRuby::Generators::Error) do
      HXRuby::Generators::Common.write_file(
        output,
        "class Owned; end\n",
        root: @root,
        kind: "ruby",
        source: "test"
      )
    end

    assert_equal "outside manifest\n", File.read(outside)
    refute_path_exists output
  end

  def test_clean_validates_every_output_before_deleting
    safe_output = File.join(@root, "generated", "safe.rb")
    FileUtils.mkdir_p(File.dirname(safe_output))
    File.write(safe_output, "safe\n")
    outside = write_outside("outside-clean.rb", "outside\n")
    symlink_output("generated/linked.rb", outside)
    write_manifest("generated/safe.rb", "generated/linked.rb")

    assert_raises(HXRuby::Generators::Error) do
      HXRuby::Generators::Common.clean_owned_outputs(@root)
    end

    assert_equal "safe\n", File.read(safe_output)
    assert_equal "outside\n", File.read(outside)
  end

  def test_client_import_rewrite_rejects_symlink_output
    client_root = File.join(@root, "app", "javascript", "railshx")
    FileUtils.mkdir_p(client_root)
    outside = write_outside("outside.js", 'import value from "./value.js";\n')
    File.symlink(outside, File.join(client_root, "linked.js"))

    error = assert_raises(HXRuby::Generators::Error) do
      Dir.chdir(@root) do
        HXRuby::Tasks.rewrite_importmap_module_imports("app/javascript/railshx", "railshx")
      end
    end

    assert_match(/must not be a symlink|resolves outside/, error.message)
    assert_equal 'import value from "./value.js";\n', File.read(outside)
  end

  def test_atomic_route_extern_write_rejects_symlink_output
    outside = write_outside("routes.hx", "before\n")
    output = symlink_output("src_haxe/routes/Routes.hx", outside)

    assert_raises(HXRuby::Generators::Error) do
      Dir.chdir(@root) do
        HXRuby::Tasks.write_route_extern_atomically(output, "after\n")
      end
    end

    assert_equal "before\n", File.read(outside)
  end

  private

  def write_outside(name, content)
    path = File.join(@tmp, name)
    File.write(path, content)
    path
  end

  def symlink_output(relative, target)
    output = File.join(@root, relative)
    FileUtils.mkdir_p(File.dirname(output))
    File.symlink(target, output)
    output
  end

  def write_manifest(*outputs)
    manifest_path = File.join(@root, ".railshx", "manifest.json")
    FileUtils.mkdir_p(File.dirname(manifest_path))
    entries = outputs.map do |output|
      { "output" => output, "kind" => "ruby", "source" => "test", "sha256" => "stale" }
    end
    File.write(manifest_path, JSON.pretty_generate({ "version" => 1, "outputs" => entries }) + "\n")
  end
end
