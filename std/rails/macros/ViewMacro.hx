package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.ruby.naming.RubyNaming;
#else
import haxe.macro.Expr;
#end

class ViewMacro {
	public static macro function renderTemplate<TLocals>(controller:Expr, template:ExprOf<rails.action_view.Template<TLocals>>, locals:ExprOf<TLocals>):Expr {
		#if macro
		var templatePath = extractTemplatePath(template);
		validateLocalsObject(locals);
		validateLocalsType(template, locals);
		var railsLocals = railsLocalsObject(locals);
		return macro $controller.render({template: $v{templatePath}, locals: $railsLocals});
		#else
		return macro null;
		#end
	}

	public static macro function renderTemplateWithLayout<TLocals>(controller:Expr, template:ExprOf<rails.action_view.Template<TLocals>>, locals:ExprOf<TLocals>,
			layout:ExprOf<String>):Expr {
		#if macro
		var templatePath = extractTemplatePath(template);
		var layoutPath = extractString(layout, "ViewMacro.renderTemplateWithLayout layout expects a string literal path.");
		validateLocalsObject(locals);
		validateLocalsType(template, locals);
		var railsLocals = railsLocalsObject(locals);
		return macro $controller.render({template: $v{templatePath}, locals: $railsLocals, layout: $v{layoutPath}});
		#else
		return macro null;
		#end
	}

	#if macro
	static function extractTemplatePath(template:Expr):String {
		return switch (unwrapTypedMarker(template).expr) {
			case ECall(callee, [path]):
				if (!isTemplatePathCallee(callee)) {
					throw "ViewMacro.renderTemplate expects rails.action_view.Template.named(...) or Template.external(...) as the template argument.";
				}
				extractString(path, "Template.named/external expects a string literal path.");
			case _:
				throw "ViewMacro.renderTemplate expects rails.action_view.Template.named(...) or Template.external(...) as the template argument.";
		}
	}

	static function unwrapTypedMarker(expr:Expr):Expr {
		return switch (expr.expr) {
			case ECheckType(inner, _): unwrapTypedMarker(inner);
			case EParenthesis(inner): unwrapTypedMarker(inner);
			case _: expr;
		}
	}

	static function isTemplatePathCallee(callee:Expr):Bool {
		return switch (callee.expr) {
			case EField(_, "named" | "external"): true;
			case _: false;
		}
	}

	static function validateLocalsObject(locals:Expr):Void {
		switch (locals.expr) {
			case EObjectDecl(fields):
				if (fields.length == 0) {
					throw "ViewMacro.renderTemplate locals must include at least one named local.";
				}
			case _:
				throw "ViewMacro.renderTemplate locals must be an object literal so Rails local names are explicit.";
		}
	}

	static function validateLocalsType(template:Expr, locals:Expr):Void {
		var expected = switch (Context.typeof(template)) {
			case TInst(classRef, [localsType]) if (classRef.get().pack.join(".") == "rails.action_view" && classRef.get().name == "Template"):
				localsType;
			case _:
				Context.error("ViewMacro.renderTemplate template argument must be rails.action_view.Template<TLocals>.", template.pos);
				return;
		}
		var actual = Context.typeof(locals);
		if (!Context.unify(actual, expected)) {
			Context.error("ViewMacro.renderTemplate locals do not match the Template<TLocals> contract.", locals.pos);
		}
	}

	static function railsLocalsObject(locals:Expr):Expr {
		return switch (locals.expr) {
			case EObjectDecl(fields):
				{
					expr: EObjectDecl([
						for (field in fields) {
							field: RubyNaming.toLocalName(field.field),
							expr: field.expr,
							quotes: field.quotes
						}
					]),
					pos: locals.pos
				};
			case _:
				locals;
		}
	}

	static function extractString(expr:Expr, message:String):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)): value;
			case _: throw message;
		}
	}
	#end
}
