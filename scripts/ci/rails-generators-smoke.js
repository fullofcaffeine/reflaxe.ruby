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

generatedMailerCompileSmoke();

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

      def file_path
        name.to_s
      end
    end
  end
end

require "generators/hxruby/install/install_generator"
require "generators/hxruby/routes/routes_generator"
require "generators/hxruby/migration/migration_generator"
require "generators/hxruby/model/model_generator"
require "generators/hxruby/mailer/mailer_generator"
require "generators/hxruby/template/template_generator"
require "generators/hxruby/test/test_generator"
require "generators/hxruby/controller/controller_generator"
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
  assert(File.read(File.join(temp, "install", "app_haxe", "Boot.hx")).include?("class Boot"), "install generator did not use source/main")
  assert(File.read(File.join(temp, "install", "app_haxe", "client", "Boot.hx")).include?("TypedTasks RailsHx client boot"), "install generator did not use app name in client boot")
  assert(File.exist?(File.join(temp, "install", "app_haxe", "routes", "AppRoutes.hx")), "install generator did not default to Haxe-owned routes")

  routes_root = File.join(temp, "routes")
  FileUtils.mkdir_p(routes_root)
  routes_fixture = File.join(root, "test", "fixtures", "rails_routes", "routes.txt")
  routes = Hxruby::RoutesGenerator.new([], {"input" => routes_fixture, "output" => "src_haxe/routes/Routes.hx"})
  routes.destination_root = routes_root
  routes.generate_routes
  assert(File.read(File.join(routes_root, "src_haxe", "routes", "Routes.hx")).include?("public static function completeTodoPath(id:RouteParam):String;"), "routes generator did not emit typed route helpers")

  scaffold = Hxruby::ScaffoldGenerator.new(["Todo", "title:String", "isCompleted:Bool"], {"controller" => true, "output" => "scaffold"})
  scaffold.destination_root = temp
  scaffold.generate_scaffold
  assert(File.exist?(File.join(temp, "scaffold", "src_haxe", "controllers", "TodosController.hx")), "scaffold generator did not write controller")
  assert(File.exist?(File.join(temp, "scaffold", "src_haxe", "routes", "AppRoutes.hx")), "scaffold generator did not default to Haxe-owned routes")

  migration = Hxruby::MigrationGenerator.new(["AddStatusToTodos", "status:string"], {"timestamp" => "20260101010200", "output" => "migration"})
  migration.destination_root = temp
  migration.generate_migration
  assert(File.read(File.join(temp, "migration", "src_haxe", "migrations", "AddStatusToTodos.hx")).include?("AddColumn"), "migration generator did not write snapshot operation")

  model = Hxruby::ModelGenerator.new(["Todo", "title:string!"], {"timestamp" => "20260101010300", "output" => "model", "validate" => ["title,presence"]})
  model.destination_root = temp
  model.generate_model
  assert(File.read(File.join(temp, "model", "src_haxe", "models", "Todo.hx")).include?("@:validates({presence: true})"), "model generator did not write typed validation")

  mailer = Hxruby::MailerGenerator.new(["User", "welcome"], {"output" => "mailer"})
  mailer.destination_root = temp
  mailer.generate_mailer
  assert(File.read(File.join(temp, "mailer", "src_haxe", "mailers", "UserMailer.hx")).include?("@:railsMailerParams(WelcomeMailerParams)"), "mailer generator did not write typed parameterized mailer")
  assert(File.exist?(File.join(temp, "mailer", "src_haxe", "views", "user_mailer", "WelcomeEmailHtmlView.hx")), "mailer generator did not write HHX html view")
  assert(File.exist?(File.join(temp, "mailer", "src_haxe", "previews", "UserMailerPreview.hx")), "mailer generator did not write preview")
  assert(File.exist?(File.join(temp, "mailer", "test_haxe", "mailers", "UserMailerHaxeTest.hx")), "mailer generator did not write Haxe-authored Rails test")

  template = Hxruby::TemplateGenerator.new(["controllers/todos/_card"], {"output" => "template", "locals" => "title:String"})
  template.destination_root = temp
  template.generate_template
  assert(File.exist?(File.join(temp, "template", "src_haxe", "views", "controllers", "todos", "CardView.hx")), "template generator did not write typed HHX source")

  test_generator = Hxruby::TestGenerator.new(["controllers/todos_request"], {"output" => "test", "type" => "request"})
  test_generator.destination_root = temp
  test_generator.generate_test
  assert(File.exist?(File.join(temp, "test", "test_haxe", "controllers", "TodosRequestHaxeTest.hx")), "test generator did not write Haxe-authored Rails test source")

  controller = Hxruby::ControllerGenerator.new(["Todos", "index", "show"], {"templates" => true, "output" => "controller"})
  controller.destination_root = temp
  controller.generate_controller
  assert(File.exist?(File.join(temp, "controller", "src_haxe", "controllers", "TodosController.hx")), "controller generator did not write controller")
  assert(File.exist?(File.join(temp, "controller", "src_haxe", "views", "todos", "IndexView.hx")), "controller generator did not write HHX view")

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
require "generators/hxruby/migration/migration_generator"
require "generators/hxruby/model/model_generator"
require "generators/hxruby/mailer/mailer_generator"
require "generators/hxruby/template/template_generator"
require "generators/hxruby/test/test_generator"
require "generators/hxruby/controller/controller_generator"
require "generators/hxruby/scaffold/scaffold_generator"
require "generators/hxruby/adopt/adopt_generator"

expected = {
  Hxruby::InstallGenerator => "hxruby:install",
  Hxruby::RoutesGenerator => "hxruby:routes",
  Hxruby::MigrationGenerator => "hxruby:migration",
  Hxruby::ModelGenerator => "hxruby:model",
  Hxruby::MailerGenerator => "hxruby:mailer",
  Hxruby::TemplateGenerator => "hxruby:template",
  Hxruby::TestGenerator => "hxruby:test",
  Hxruby::ControllerGenerator => "hxruby:controller",
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

function assert(condition, message) {
  if (!condition) fail(message);
}

function generatedMailerCompileSmoke() {
  const temp = mkdtempSync(join(tmpdir(), "hxruby-mailer-generator."));
  const generated = join(temp, "app");
  const output = join(temp, "out");
  try {
    run("ruby", ["-I", join(root, "lib"), join(root, "scripts", "rails", "mailer.rb"), "UserMailer", "welcome", "--output", generated]);
    writeFileSync(
      join(generated, "SmokeMain.hx"),
      [
        "import mailers.UserMailer;",
        "class SmokeMain {",
        "  static function main() {",
        '    UserMailer.withParams({email: "reader@example.test", name: "Reader", message: "Generated mailer compile"}).welcome();',
        "  }",
        "}",
        "",
      ].join("\n"),
    );

    const reflaxeCandidates = [
      join(root, "vendor", "reflaxe", "src"),
      join(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
      join(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
    ];
    const reflaxeSrc = reflaxeCandidates.find((candidate) => existsSync(join(candidate, "reflaxe", "ReflectCompiler.hx")));
    assert(reflaxeSrc, "unable to find vendored Reflaxe source for generated mailer compile smoke");

    run("haxe", [
      "-D", `ruby_output=${output}`,
      "-D", "reflaxe_runtime",
      "-D", "reflaxe_ruby_rails",
      "-cp", join(root, "src"),
      "-cp", generated,
      "-cp", join(generated, "src_haxe"),
      "-cp", join(generated, "test_haxe"),
      "-cp", reflaxeSrc,
      "--macro", "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro", "reflaxe.ruby.CompilerInit.Start()",
      "--macro", 'include("previews")',
      "--macro", 'include("test_haxe")',
      "-main", "SmokeMain",
    ]);
    run("ruby", ["-c", join(output, "app", "haxe_gen", "mailers", "user_mailer.rb")]);
    run("ruby", ["-c", join(output, "test", "mailers", "previews", "user_mailer_preview.rb")]);
  } finally {
    rmSync(temp, { force: true, recursive: true });
  }
}

function fail(message) {
  console.error(`[rails-generators] ERROR: ${message}`);
  process.exit(1);
}
