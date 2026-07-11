#!/usr/bin/env node

const { existsSync, mkdirSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const generatedRoot = join(root, "test", ".generated", "ruby_callable_diagnostics");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];
const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));

if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for Ruby callable diagnostics.");
  process.exit(1);
}

const cases = [
  {
    name: "block_on_variable",
    expected: "@:rubyBlockArg is valid only on a method declaration",
    source: `
extern class NativeApi {
  @:rubyBlockArg
  public static var callback:Int->Void;
}
class Main {
  static function main():Void NativeApi.callback(1);
}
`,
  },
  {
    name: "block_without_function",
		expected: "@:rubyBlockArg on method `each` requires the final Haxe parameter of at least one overload to have a precise function type",
    source: `
extern class NativeApi {
  @:rubyBlockArg
  public static function each(values:Array<Int>, count:Int):Void;
}
class Main {
  static function main():Void NativeApi.each([1], 1);
}
`,
  },
  {
    name: "kwargs_without_carrier",
		expected: "@:rubyKwargs on method `describe` requires a typed anonymous-object/typedef carrier as the final Haxe parameter",
    source: `
extern class NativeApi {
  @:rubyKwargs
  public static function describe(value:String):Void;
}
class Main {
  static function main():Void NativeApi.describe("value");
}
`,
  },
  {
    name: "kwargs_after_block",
		expected: "@:rubyBlockArg on method `visit` requires the final Haxe parameter of at least one overload to have a precise function type",
    source: `
extern class NativeApi {
  @:rubyKwargs
  @:rubyBlockArg
  public static function visit(block:Int->Void, options:{name:String}):Void;
}
class Main {
  static function main():Void NativeApi.visit(value -> {}, {name: "ruby"});
}
`,
  },
	{
		name: "metadata_arguments",
		expected: "@:rubyBlockArg on method `visit` does not accept arguments",
    source: `
extern class NativeApi {
  @:rubyBlockArg("manual")
  public static function visit(block:Int->Void):Void;
}
class Main {
  static function main():Void NativeApi.visit(value -> {});
}
`,
	},
	{
		name: "duplicate_block_metadata",
		expected: "@:rubyBlockArg may appear only once on method `visit`",
		source: `
extern class NativeApi {
  @:rubyBlockArg
  @:rubyBlockArg
  public static function visit(block:Int->Void):Void;
}
class Main {
  static function main():Void NativeApi.visit(value -> {});
}
`,
	},
	{
		name: "invalid_native_name",
    expected: "is not a valid Ruby method name",
    source: `
class NativeApi {
  @:native("bad method")
  public static function invalid():Void {}
}
class Main {
  static function main():Void NativeApi.invalid();
}
`,
  },
	{
		name: "dynamic_block_method",
    expected: "cannot be used on a Haxe dynamic method",
    source: `
class NativeApi {
  public function new() {}
  @:rubyBlockArg
  public dynamic function visit(block:Int->Void):Void block(1);
}
class Main {
  static function main():Void new NativeApi().visit(value -> {});
}
`,
	},
	{
		name: "dynamic_external_attribute",
		expected: "@:railsExternalAttribute requires a precise field type",
		rails: true,
		source: `
@:railsModel
class Model extends rails.active_record.Base<Model> {
  @:railsExternalAttribute
  public var payload:Dynamic;
}
class Main {
  static function main():Void {}
}
`,
	},
];

rmSync(generatedRoot, { force: true, recursive: true });
mkdirSync(generatedRoot, { recursive: true });

for (const testCase of cases) {
  const sourceRoot = join(generatedRoot, testCase.name, "src");
  const outputRoot = join(generatedRoot, testCase.name, "out");
  mkdirSync(sourceRoot, { recursive: true });
  writeFileSync(join(sourceRoot, "Main.hx"), testCase.source.trimStart());
	const args = [
		"-D",
		`ruby_output=${outputRoot}`,
		"-D",
		"reflaxe_runtime",
		"-cp",
		join(root, "src"),
		"-cp",
		join(root, "std"),
		"-cp",
		sourceRoot,
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
		"-main",
		"Main",
	];
	if (testCase.rails) {
		args.splice(4, 0, "-D", "reflaxe_ruby_rails");
	}
	const result = spawnSync("haxe", args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  const diagnostics = `${result.stdout}${result.stderr}`;
  if (result.status === 0) {
    console.error(`Expected callable diagnostic case to fail: ${testCase.name}`);
    process.exit(1);
  }
  if (!diagnostics.includes(testCase.expected)) {
    console.error(`Callable diagnostic mismatch for ${testCase.name}`);
    console.error(`Expected diagnostic containing: ${testCase.expected}`);
    console.error(diagnostics);
    process.exit(1);
  }
}

console.log(`[ruby-callable-diagnostics] OK: ${cases.length} invalid ABI declarations rejected`);
