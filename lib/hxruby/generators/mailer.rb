# frozen_string_literal: true

require "optparse"
require_relative "common"

module HXRuby
  module Generators
    class Mailer
      PACKAGE_PATTERN = /\A[A-Za-z_][A-Za-z0-9_]*(?:[.][A-Za-z_][A-Za-z0-9_]*)*\z/
      NAME_PATTERN = /\A[A-Za-z_][A-Za-z0-9_]*\z/

      def self.run(argv)
        new(parse(argv)).run
      end

      def self.parse(argv)
        options = {
          name: nil,
          action: "welcome",
          output: ".",
          haxe_dir: "src_haxe/mailers",
          package: "mailers",
          views_dir: "src_haxe/views",
          views_package: "views",
          previews_dir: "src_haxe/previews",
          previews_package: "previews",
          tests_dir: "test_haxe/mailers",
          tests_package: "test_haxe.mailers",
          skip_preview: false,
          skip_test: false,
          force: false,
        }
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: hxruby:mailer NAME [action] [options]"
          opts.on("--output PATH") { |value| options[:output] = value }
          opts.on("--haxe-dir PATH") { |value| options[:haxe_dir] = value }
          opts.on("--package NAME") { |value| options[:package] = value }
          opts.on("--views-dir PATH") { |value| options[:views_dir] = value }
          opts.on("--views-package NAME") { |value| options[:views_package] = value }
          opts.on("--previews-dir PATH") { |value| options[:previews_dir] = value }
          opts.on("--previews-package NAME") { |value| options[:previews_package] = value }
          opts.on("--tests-dir PATH") { |value| options[:tests_dir] = value }
          opts.on("--tests-package NAME") { |value| options[:tests_package] = value }
          opts.on("--skip-preview") { options[:skip_preview] = true }
          opts.on("--skip-test") { options[:skip_test] = true }
          opts.on("--force") { options[:force] = true }
        end
        remaining = parser.parse!(argv)
        options[:name] = remaining.shift
        options[:action] = remaining.shift || options[:action]
        raise Error, "Missing required mailer NAME" if options[:name].to_s.empty?

        options
      end

      def initialize(options)
        @mailer_name = class_name(options.fetch(:name))
        @action = Common.haxe_identifier(options.fetch(:action), fallback: "welcome")
        @output_dir = File.expand_path(options.fetch(:output))
        @haxe_dir = Common.safe_relative_path(options.fetch(:haxe_dir), label: "--haxe-dir")
        @package_name = options.fetch(:package)
        @views_dir = Common.safe_relative_path(options.fetch(:views_dir), label: "--views-dir")
        @views_package = options.fetch(:views_package)
        @previews_dir = Common.safe_relative_path(options.fetch(:previews_dir), label: "--previews-dir")
        @previews_package = options.fetch(:previews_package)
        @tests_dir = Common.safe_relative_path(options.fetch(:tests_dir), label: "--tests-dir")
        @tests_package = options.fetch(:tests_package)
        @skip_preview = options.fetch(:skip_preview)
        @skip_test = options.fetch(:skip_test)
        @force = options.fetch(:force)
        validate_static_options!
      end

      def run
        write(File.join(@haxe_dir, "#{@mailer_name}.hx"), render_mailer, kind: "haxe_mailer_source")
        write(File.join(@views_dir, mailer_view_dir, "#{html_view_class}.hx"), render_html_view, kind: "haxe_mailer_view_source")
        write(File.join(@views_dir, mailer_view_dir, "#{text_view_class}.hx"), render_text_view, kind: "haxe_mailer_view_source")
        write(File.join(@previews_dir, "#{preview_class}.hx"), render_preview, kind: "haxe_mailer_preview_source") unless @skip_preview
        write(File.join(@tests_dir, "#{test_class}.hx"), render_test, kind: "haxe_rails_test_source") unless @skip_test
      end

      private

      def validate_static_options!
        raise Error, "Mailer name must be a safe Haxe class name" unless @mailer_name.match?(/\A[A-Z][A-Za-z0-9_]*Mailer\z/)
        raise Error, "Mailer action must be a safe Haxe method name" unless @action.match?(NAME_PATTERN)
        [@package_name, @views_package, @previews_package, @tests_package].each do |package_name|
          raise Error, "Haxe package names must be safe dot-separated identifiers" unless package_name.match?(PACKAGE_PATTERN)
        end
      end

      def class_name(raw)
        name = raw.to_s
        name = Common.class_name_from_path(name) unless name.match?(/\A[A-Z]/)
        name.end_with?("Mailer") ? name : "#{name}Mailer"
      end

      def write(relative_path, content, kind:)
        Common.write_file(
          File.join(@output_dir, relative_path),
          content,
          force: @force,
          root: @output_dir,
          kind: kind,
          source: "hxruby:mailer"
        )
      end

      def render_mailer
        [
          "package #{@package_name};",
          "",
          "import rails.action_mailer.MailLayout;",
          "import rails.action_mailer.MessageDelivery;",
          "import rails.action_view.Template;",
          "import rails.macros.MailerMacro;",
          "import #{view_package}.#{html_view_class};",
          "import #{view_package}.#{text_view_class};",
          "import #{view_package}.#{html_view_class}.#{locals_type};",
          "",
          "typedef #{params_type} = {",
          "\tvar email:String;",
          "\tvar name:String;",
          "\tvar message:String;",
          "}",
          "",
          "// Generated by HXRuby::Generators::Mailer.",
          "// Demonstrates: a typed RailsHx ActionMailer source file. Haxe owns",
          "// the params typedef and HHX template contracts; Rails receives a normal",
          "// ActionMailer::Base subclass plus ERB templates after compilation.",
          "// Type safety: @:railsMailerParams generates withParams(...) and p.<field>",
          "// tokens, so callers cannot omit required params and mailer code reads",
          "// params through typed MailParam<T> refs instead of Dynamic hashes.",
          "@:railsMailer",
          "@:railsMailerParams(#{params_type})",
          "class #{@mailer_name} extends rails.action_mailer.Base {",
          "\tpublic function #{@action}():MessageDelivery {",
          "\t\tvar email = param(#{@mailer_name}.p.email);",
          "\t\tvar name = param(#{@mailer_name}.p.name);",
          "\t\tvar message = param(#{@mailer_name}.p.message);",
          "\t\tvar locals:#{locals_type} = {name: name, message: message, productName: \"RailsHx\"};",
          "\t\treturn MailerMacro.mailMultipart(this, {",
          "\t\t\tto: email,",
          "\t\t\tfrom: \"team@example.test\",",
          "\t\t\tsubject: \"#{human_action} from typed RailsHx\",",
          "\t\t\tlayout: MailLayout.none()",
          "\t\t}, (Template.of(#{html_view_class}) : Template<#{locals_type}>), locals,",
          "\t\t\t(Template.of(#{text_view_class}) : Template<#{locals_type}>), locals);",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_html_view
        [
          "package #{view_package};",
          "",
          "import rails.action_view.HtmlNode;",
          "",
          "typedef #{locals_type} = {",
          "\tvar name:String;",
          "\tvar message:String;",
          "\tvar productName:String;",
          "}",
          "",
          "// Generated by HXRuby::Generators::Mailer.",
          "// Demonstrates: typed HHX mailer HTML. The compiler emits ordinary ERB",
          "// under app/views/#{template_base}.html.erb; no raw ERB is authored here.",
          "@:railsTemplate(#{Common.haxe_string(template_base)})",
          "@:railsTemplateAst(\"render\")",
          "class #{html_view_class} {",
          "\tpublic static function render(locals:#{locals_type}):HtmlNode {",
          "\t\treturn <section class=\"mail-shell\">",
          "\t\t\t<h1>Hello ${locals.name}</h1>",
          "\t\t\t<p>${locals.message}</p>",
          "\t\t\t<p>Sent from ${locals.productName}.</p>",
          "\t\t</section>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_text_view
        [
          "package #{view_package};",
          "",
          "import rails.action_view.HtmlNode;",
          "#{locals_import}",
          "",
          "// Generated by HXRuby::Generators::Mailer.",
          "// Demonstrates: typed HHX for a text-part template. Rails still receives",
          "// a normal .text.erb artifact generated from this Haxe source.",
          "@:railsTemplate(#{Common.haxe_string("#{template_base}.text")})",
          "@:railsTemplateAst(\"render\")",
          "class #{text_view_class} {",
          "\tpublic static function render(locals:#{locals_type}):HtmlNode {",
          "\t\treturn <>Hello ${locals.name}\\n${locals.message}\\nSent from ${locals.productName}.</>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_preview
        [
          "package #{@previews_package};",
          "",
          "import #{@package_name}.#{@mailer_name};",
          "import rails.action_mailer.MessageDelivery;",
          "",
          "// Generated by HXRuby::Generators::Mailer.",
          "// Demonstrates: a Haxe-authored ActionMailer preview. Rails discovers the",
          "// generated Ruby under test/mailers/previews after `bundle exec rake hxruby:compile`.",
          "@:railsMailerPreview",
          "class #{preview_class} extends rails.action_mailer.Preview {",
          "\tpublic function #{@action}():MessageDelivery {",
          "\t\treturn #{@mailer_name}.withParams({",
          "\t\t\temail: \"preview@example.test\",",
          "\t\t\tname: \"Preview User\",",
          "\t\t\tmessage: \"Previewed through typed RailsHx mailer params.\"",
          "\t\t}).#{@action}();",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_test
        [
          "package #{@tests_package};",
          "",
          "import #{@package_name}.#{@mailer_name};",
          "import rails.test.Assert.*;",
          "import rails.test.Dsl.*;",
          "import rails.test.ModelTestCase;",
          "",
          "// Generated by HXRuby::Generators::Mailer.",
          "// Demonstrates: a Haxe-authored Rails/Minitest source file for the mailer.",
          "// The compiler emits an ordinary Rails test under test/generated/**.",
          "@:railsTest(\"mailers/#{Common.file_name(@mailer_name)}_haxe_test\")",
          "class #{test_class} extends ModelTestCase {",
          "\t@:railsTests",
          "\tstatic function define():Void {",
          "\t\ttest(\"typed parameterized mailer builds a message\", () -> {",
          "\t\t\tvar mail:Dynamic = #{@mailer_name}.withParams({",
          "\t\t\t\temail: \"reader@example.test\",",
          "\t\t\t\tname: \"Reader\",",
          "\t\t\t\tmessage: \"Generated mailer test\"",
          "\t\t\t}).#{@action}();",
          "\t\t\tequal(\"#{human_action} from typed RailsHx\", mail.subject);",
          "\t\t});",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def view_package
        "#{@views_package}.#{mailer_view_package}"
      end

      def mailer_view_package
        Common.file_name(@mailer_name)
      end

      def mailer_view_dir
        mailer_view_package.tr(".", "/")
      end

      def template_base
        "mailers/#{Common.file_name(@mailer_name)}/#{Common.file_name(@action)}"
      end

      def html_view_class
        "#{action_class}EmailHtmlView"
      end

      def text_view_class
        "#{action_class}EmailTextView"
      end

      def locals_type
        "#{action_class}EmailLocals"
      end

      def params_type
        "#{action_class}MailerParams"
      end

      def preview_class
        "#{@mailer_name}Preview"
      end

      def test_class
        "#{@mailer_name}HaxeTest"
      end

      def action_class
        Common.class_name_from_path(@action)
      end

      def human_action
        @action.gsub(/_+/, " ").split.map(&:capitalize).join(" ")
      end

      def locals_import
        "import #{view_package}.#{html_view_class}.#{locals_type};"
      end
    end
  end
end
