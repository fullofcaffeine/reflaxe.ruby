#!/usr/bin/env node

const { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");

const root = resolve(__dirname, "..", "..");

run("ruby", ["-I", join(root, "lib"), "-e", noRailsSmokeSource()]);

const railsCheck = spawnSync("ruby", ["-e", "require 'rails/generators'; print 'ok'"], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (railsCheck.status === 0) {
  run("ruby", ["-I", join(root, "lib"), "-e", realRailsLoadSmokeSource()]);
} else if (process.env.REQUIRE_RAILS === "1") {
  process.stderr.write(railsCheck.stderr);
  fail("REQUIRE_RAILS=1 but railties is not available");
} else {
  process.stdout.write("[rails-generators] Skipped real Rails generator load smoke; railties unavailable.\n");
}

console.log("[rails-generators] OK");

function noRailsSmokeSource() {
  return String.raw`
require "fileutils"
require "tmpdir"
require "stringio"

module Rails
  module Generators
    class Base
      class << self
        attr_accessor :declared_arguments, :declared_options

        def inherited(child)
          child.declared_arguments = (declared_arguments || []).map(&:dup)
          child.declared_options = (declared_options || {}).dup
        end

        def desc(*); end

        def argument(name, options = {})
          self.declared_arguments ||= []
          self.declared_arguments << [name, options]
          attr_accessor name
        end

        def class_option(name, options = {})
          self.declared_options ||= {}
          self.declared_options[name] = options
        end
      end

      attr_accessor :destination_root, :options

      def initialize(args = [], options = {}, _config = nil)
        @options = options
        assign_arguments(args)
      end

      private

      def assign_arguments(args)
        remaining = args.dup
        self.class.declared_arguments.to_a.each do |name, options|
          value = options[:type] == :array ? remaining : remaining.shift
          instance_variable_set("@#{name}", value)
        end
      end
    end

    class NamedBase < Base
      argument :name, type: :string, required: true

      def class_name
        name.to_s.split(/[_-]/).map { |part| part[0].upcase + part[1..] }.join
      end
    end
  end
end

require "generators/hxruby/install/install_generator"
require "generators/hxruby/routes/routes_generator"
require "generators/hxruby/scaffold/scaffold_generator"
require "generators/hxruby/adopt/adopt_generator"

def assert(condition, message)
  abort("[rails-generators] ERROR: #{message}") unless condition
end

root = ${JSON.stringify(root)}
temp = Dir.mktmpdir("hxruby-rails-generators.")
begin
  install = Hxruby::InstallGenerator.new(["TypedTasks"], {"source" => "app_haxe", "main" => "Boot"})
  install.destination_root = File.join(temp, "install")
  install.install_railshx
  assert(File.exist?(File.join(temp, "install", "build.hxml")), "install generator did not write build.hxml")
  assert(File.read(File.join(temp, "install", "app_haxe", "Boot.hx")).include?("TypedTasks RailsHx compile"), "install generator did not use app name/source/main")

  routes_root = File.join(temp, "routes")
  FileUtils.mkdir_p(routes_root)
  routes_fixture = File.join(root, "test", "fixtures", "rails_routes", "routes.txt")
  routes = Hxruby::RoutesGenerator.new([], {"input" => routes_fixture, "output" => "src_haxe/routes/Routes.hx"})
  routes.destination_root = routes_root
  routes.generate_routes
  assert(File.read(File.join(routes_root, "src_haxe", "routes", "Routes.hx")).include?("public static function todoPath(id:RouteParam):String;"), "routes generator did not emit typed route helpers")

  scaffold = Hxruby::ScaffoldGenerator.new(["Todo", "title:String", "isCompleted:Bool"], {"controller" => true, "output" => "scaffold"})
  scaffold.destination_root = temp
  scaffold.generate_scaffold
  assert(File.exist?(File.join(temp, "scaffold", "src_haxe", "controllers", "TodosController.hx")), "scaffold generator did not write controller")

  adopt_root = File.join(temp, "adopt")
  FileUtils.mkdir_p(File.join(adopt_root, "app", "services"))
  FileUtils.mkdir_p(File.join(adopt_root, "app", "views", "legacy"))
  File.write(File.join(adopt_root, "app", "services", "legacy_price_formatter.rb"), "class LegacyPriceFormatter\nend\n")
  File.write(File.join(adopt_root, "app", "views", "legacy", "_badge.html.erb"), "<%= label %>\n")

  discover = Hxruby::AdoptGenerator.new([], {"discover" => true})
  discover.destination_root = adopt_root
  stdout = $stdout
  captured = StringIO.new
  $stdout = captured
  discover.adopt_boundaries
  $stdout = stdout
  assert(captured.string.include?("--service LegacyPriceFormatter"), "discover did not report service candidate")
  assert(captured.string.include?("--template legacy/badge"), "discover did not report template candidate")
  assert(!File.exist?(File.join(adopt_root, "src_haxe")), "discover wrote files")

  adopt = Hxruby::AdoptGenerator.new([], {"service" => "LegacyPriceFormatter", "template" => "legacy/badge", "locals" => "label:String"})
  adopt.destination_root = adopt_root
  adopt.adopt_boundaries
  assert(File.exist?(File.join(adopt_root, "src_haxe", "interop", "LegacyPriceFormatter.hx")), "adopt did not write service wrapper")
  assert(File.exist?(File.join(adopt_root, "src_haxe", "interop", "templates", "LegacyBadgeTemplate.hx")), "adopt did not write template wrapper")
ensure
  FileUtils.remove_entry(temp) if temp && File.exist?(temp)
end
`;
}

function realRailsLoadSmokeSource() {
  return String.raw`
require "rails/generators"
require "generators/hxruby/install/install_generator"
require "generators/hxruby/routes/routes_generator"
require "generators/hxruby/scaffold/scaffold_generator"
require "generators/hxruby/adopt/adopt_generator"

expected = {
  Hxruby::InstallGenerator => "hxruby:install",
  Hxruby::RoutesGenerator => "hxruby:routes",
  Hxruby::ScaffoldGenerator => "hxruby:scaffold",
  Hxruby::AdoptGenerator => "hxruby:adopt"
}

expected.each do |klass, namespace|
  actual = klass.namespace
  abort("[rails-generators] ERROR: #{klass} namespace #{actual.inspect} != #{namespace.inspect}") unless actual == namespace
end
`;
}

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

function fail(message) {
  console.error(`[rails-generators] ERROR: ${message}`);
  process.exit(1);
}
