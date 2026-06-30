package unitstd_ruby;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Adapts checked-in upstream Haxe `.unit.hx` expression specs to local asserts.

	Upstream fixtures stay expression-shaped. This macro parses them at compile
	time and rewrites assertion-like expressions such as `a == b`, `t(expr)`, and
	`feq(actual, expected)` so the generated Ruby lane owns runtime semantics.
**/
class UpstreamUnitStdMacro {
	public static macro function assertSpec(relativePath:String):Expr {
		var fixturePath = fixturePath(relativePath);
		if (!sys.FileSystem.exists(fixturePath)) {
			Context.error('Missing upstream unitstd fixture: ${fixturePath}', Context.currentPos());
		}

		var source = sys.io.File.getContent(fixturePath);
		var parsed = Context.parseInlineString("{\n" + source + "\n}", Context.currentPos());
		return transform(parsed, relativePath);
	}

	#if macro
	static function fixturePath(relativePath:String):String {
		return haxe.io.Path.join([Sys.getCwd(), "test/upstream_unitstd/upstream", relativePath]);
	}

	static function transform(expression:Expr, relativePath:String):Expr {
		return switch expression.expr {
			case EBlock(expressions):
				{expr: EBlock([for (statement in expressions) transformStatement(statement, relativePath)]), pos: expression.pos};
			default:
				transformStatement(expression, relativePath);
		}
	}

	static function transformStatement(expression:Expr, relativePath:String):Expr {
		return switch expression.expr {
			case EBinop(OpEq, left, right) if (boolLiteralValue(right) != null):
				boolLiteralValue(right) ? assertTrue(left, expression, relativePath) : assertFalse(left, expression, relativePath);

			case EBinop(OpEq, left, right) if (boolLiteralValue(left) != null):
				boolLiteralValue(left) ? assertTrue(right, expression, relativePath) : assertFalse(right, expression, relativePath);

			case EBinop(OpNotEq, left, right) if (boolLiteralValue(right) != null):
				boolLiteralValue(right) ? assertFalse(left, expression, relativePath) : assertTrue(left, expression, relativePath);

			case EBinop(OpNotEq, left, right) if (boolLiteralValue(left) != null):
				boolLiteralValue(left) ? assertFalse(right, expression, relativePath) : assertTrue(right, expression, relativePath);

			case EBinop(OpEq, left, right):
				assertTrue({expr: EBinop(OpEq, left, right), pos: expression.pos}, expression, relativePath);

			case EBinop(OpNotEq, left, right):
				assertTrue({expr: EBinop(OpNotEq, left, right), pos: expression.pos}, expression, relativePath);

			case EBinop((OpGt | OpGte | OpLt | OpLte), left, right):
				assertTrue({expr: expression.expr, pos: expression.pos}, expression, relativePath);

			case ECall({expr: EConst(CIdent("t"))}, [value]):
				assertTrue(value, expression, relativePath);

			case ECall({expr: EConst(CIdent("f"))}, [value]):
				assertFalse(value, expression, relativePath);

			case ECall({expr: EConst(CIdent("eq"))}, [expected, actual]):
				assertTrue({expr: EBinop(OpEq, actual, expected), pos: expression.pos}, expression, relativePath);

			case ECall({expr: EConst(CIdent("neq"))}, [expected, actual]):
				assertTrue({expr: EBinop(OpNotEq, actual, expected), pos: expression.pos}, expression, relativePath);

			case ECall({expr: EConst(CIdent("feq"))}, [actual, expected]):
				assertFloatNear(actual, expected, expression, relativePath);

			case ECall({expr: EConst(CIdent("aeq"))}, [expected, actual]):
				assertTrue({expr: EBinop(OpEq, actual, expected), pos: expression.pos}, expression, relativePath);

			case ECall({expr: EConst(CIdent("unspec"))}, [_]):
				macro {};

			case EBinop(OpIn, left, right):
				assertTrue(macro $right.indexOf($left) != -1, expression, relativePath);

			case EBlock(expressions):
				{expr: EBlock([for (statement in expressions) transformStatement(statement, relativePath)]), pos: expression.pos};

			case EIf(condition, thenExpression, elseExpression):
				{
					expr: EIf(condition, transformStatement(thenExpression, relativePath),
						elseExpression == null ? null : transformStatement(elseExpression, relativePath)),
					pos: expression.pos
				};

			case EWhile(condition, body, normalWhile):
				{expr: EWhile(condition, transformStatement(body, relativePath), normalWhile), pos: expression.pos};

			case EFor(iterator, body):
				{expr: EFor(iterator, transformStatement(body, relativePath)), pos: expression.pos};

			case ETry(body, catches):
				{
					expr: ETry(transformStatement(body, relativePath), [
						for (handler in catches)
							{
								name: handler.name,
								type: handler.type,
								expr: transformStatement(handler.expr, relativePath)
							}
					]),
					pos: expression.pos
				};

			default:
				expression;
		}
	}

	static function assertTrue(condition:Expr, source:Expr, relativePath:String):Expr {
		return macro unitstd_ruby.Assert.isTrue($condition, $v{message(source, relativePath)});
	}

	static function assertFalse(condition:Expr, source:Expr, relativePath:String):Expr {
		return macro unitstd_ruby.Assert.isFalse($condition, $v{message(source, relativePath)});
	}

	static function assertFloatNear(actual:Expr, expected:Expr, source:Expr, relativePath:String):Expr {
		return macro unitstd_ruby.Assert.inDelta($expected, $actual, 0.00001, $v{message(source, relativePath)});
	}

	static function boolLiteralValue(expression:Expr):Null<Bool> {
		return switch expression.expr {
			case EConst(CIdent("true")):
				true;
			case EConst(CIdent("false")):
				false;
			default:
				null;
		}
	}

	static function message(source:Expr, relativePath:String):String {
		var location = Context.getPosInfos(source.pos);
		return 'upstream unitstd ${relativePath} at ${workspaceRelativePath(location.file)}:${location.min}';
	}

	static function workspaceRelativePath(path:String):String {
		var workspace = haxe.io.Path.normalize(Sys.getCwd());
		var normalizedPath = haxe.io.Path.normalize(path);
		var workspacePrefix = workspace + "/";
		if (StringTools.startsWith(normalizedPath, workspacePrefix)) {
			return normalizedPath.substr(workspacePrefix.length);
		}
		return normalizedPath;
	}
	#end
}
