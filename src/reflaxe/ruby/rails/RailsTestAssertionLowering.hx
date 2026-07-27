package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Type.TypedExpr;
import reflaxe.ruby.ast.RubyAST.RubyExpr;

typedef RailsTestAssertionRenderers = {
	final compileExpr:TypedExpr->RubyExpr;
	final printInlineExpr:TypedExpr->String;
	final renderRubyProc:TypedExpr->String;
	final renderRubyBlock:TypedExpr->String;
	final railsStatusArg:TypedExpr->Null<String>;
}

/**
	Owns adapter-specific lowering for compiler-erased Rails test assertions.

	The root compiler supplies expression/block renderers because those remain
	part of the shared Ruby lowering pipeline. This module owns only the closed
	assertion-name-to-native-Rails mapping and fails closed when an assertion has
	no verified contract for the selected test adapter.
**/
class RailsTestAssertionLowering {
	public static function compile(owner:String, name:String, params:Array<TypedExpr>, adapter:RailsTestAdapter,
			renderers:RailsTestAssertionRenderers):Null<RubyExpr> {
		if (owner == "rails.test.ActionCableAssert") {
			return compileActionCable(name, params, adapter, renderers);
		}
		if (owner != "rails.test.Assert") {
			return null;
		}
		return switch (adapter) {
			case RailsMinitest: compileMinitest(name, params, renderers);
			case RailsRspec: compileRspec(name, params, renderers);
		}
	}

	static function compileActionCable(name:String, params:Array<TypedExpr>, adapter:RailsTestAdapter, renderers:RailsTestAssertionRenderers):Null<RubyExpr> {
		if (name != "assertBroadcasts" || params.length != 3) {
			return null;
		}
		return switch (adapter) {
			case RailsMinitest:
				RubyRawExpr("assert_broadcasts(" + renderers.printInlineExpr(params[0]) + ", " + renderers.printInlineExpr(params[1]) + ") "
					+ renderers.renderRubyBlock(params[2]));
			case RailsRspec:
				Context.error("rails.test.ActionCableAssert.assertBroadcasts currently supports only the rails.minitest adapter; RailsHx has no verified RSpec ActionCable matcher contract yet.",
					params[0].pos);
				RubyNil;
		}
	}

	static function compileMinitest(name:String, params:Array<TypedExpr>, renderers:RailsTestAssertionRenderers):Null<RubyExpr> {
		var args = [for (param in params) renderers.compileExpr(param)];
		return switch (name) {
			case "equal" | "assertEqual":
				RubyCall(null, "assert_equal", args);
			case "notEqual" | "assertNotEqual":
				RubyCall(null, "assert_not_equal", args);
			case "truthy" | "assertTrue":
				RubyCall(null, "assert", args);
			case "falsy" | "assertFalse":
				RubyCall(null, "assert_not", args);
			case "includes" | "assertIncludes":
				RubyCall(null, "assert_includes", args);
			case "notIncludes" | "assertNotIncludes":
				RubyCall(null, "assert_not_includes", args);
			case "nilValue" | "assertNil":
				RubyCall(null, "assert_nil", args);
			case "notNil" | "assertNotNil":
				RubyCall(null, "assert_not_nil", args);
			case "assertResponse" if (params.length == 1):
				var status = renderers.railsStatusArg(params[0]);
				status == null ? RubyCall(null, "assert_response", args) : RubyCall(null, "assert_response", [RubyRawExpr(status)]);
			case "assertRedirectedTo":
				RubyCall(null, "assert_redirected_to", args);
			case "assertDifference" if (params.length == 3):
				RubyRawExpr("assert_difference(" + renderers.renderRubyProc(params[0]) + ", " + renderers.printInlineExpr(params[1]) + ") "
					+ renderers.renderRubyBlock(params[2]));
			case "assertNoDifference" if (params.length == 2):
				RubyRawExpr("assert_no_difference(" + renderers.renderRubyProc(params[0]) + ") " + renderers.renderRubyBlock(params[1]));
			case _:
				null;
		}
	}

	static function compileRspec(name:String, params:Array<TypedExpr>, renderers:RailsTestAssertionRenderers):Null<RubyExpr> {
		return switch (name) {
			case "equal" | "assertEqual" if (params.length == 2):
				RubyRawExpr("expect(" + renderers.printInlineExpr(params[1]) + ").to eq(" + renderers.printInlineExpr(params[0]) + ")");
			case "notEqual" | "assertNotEqual" if (params.length == 2):
				RubyRawExpr("expect(" + renderers.printInlineExpr(params[1]) + ").not_to eq(" + renderers.printInlineExpr(params[0]) + ")");
			case "truthy" | "assertTrue" if (params.length == 1):
				RubyRawExpr("expect(" + renderers.printInlineExpr(params[0]) + ").to be_truthy");
			case "falsy" | "assertFalse" if (params.length == 1):
				RubyRawExpr("expect(" + renderers.printInlineExpr(params[0]) + ").to be_falsey");
			case "includes" | "assertIncludes" if (params.length == 2):
				RubyRawExpr("expect(" + renderers.printInlineExpr(params[0]) + ").to include(" + renderers.printInlineExpr(params[1]) + ")");
			case "notIncludes" | "assertNotIncludes" if (params.length == 2):
				RubyRawExpr("expect(" + renderers.printInlineExpr(params[0]) + ").not_to include(" + renderers.printInlineExpr(params[1]) + ")");
			case "nilValue" | "assertNil" if (params.length == 1):
				RubyRawExpr("expect(" + renderers.printInlineExpr(params[0]) + ").to be_nil");
			case "notNil" | "assertNotNil" if (params.length == 1):
				RubyRawExpr("expect(" + renderers.printInlineExpr(params[0]) + ").not_to be_nil");
			case "assertResponse" if (params.length == 1):
				var status = renderers.railsStatusArg(params[0]);
				RubyRawExpr("expect(response).to have_http_status(" + (status == null ? renderers.printInlineExpr(params[0]) : status) + ")");
			case "assertRedirectedTo" if (params.length == 1):
				RubyRawExpr("expect(response).to redirect_to(" + renderers.printInlineExpr(params[0]) + ")");
			case "assertDifference" if (params.length == 3):
				RubyRawExpr("expect " + renderers.renderRubyBlock(params[2]) + ".to change " + renderers.renderRubyBlock(params[0]) + ".by("
					+ renderers.printInlineExpr(params[1]) + ")");
			case "assertNoDifference" if (params.length == 2):
				RubyRawExpr("expect " + renderers.renderRubyBlock(params[1]) + ".not_to change " + renderers.renderRubyBlock(params[0]));
			case _:
				null;
		}
	}
}
#end
