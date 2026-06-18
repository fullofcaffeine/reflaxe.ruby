package views;

import models.Todo;
import rails.action_view.HtmlNode;
import routes.Routes;
import shared.TodoHooks;

typedef TodoFormLocals = {
	var sampleUserId:Int;
}

// Typed Rails form partial.
//
// Demonstrates: Rails form helpers authored as HHX tags and backed by typed
// model field refs.
// Type safety: `Todo.railsParamKey` supplies the form scope; `Todo.f.userId`,
// `Todo.f.title`, and `Todo.f.notes` are generated field refs, so renamed/missing
// model fields fail in Haxe instead of becoming broken Rails params.
// IntelliSense: editors should complete `Todo.f.*`, `Routes.todosPath`, and the
// `sampleUserId` local.
// Ruby/Rails output: normal Rails form builder ERB with strong Rails param names.
@:railsTemplate("controllers/todos/_typed_form")
@:railsTemplateAst("render")
class TodoFormView {
	public static function render(locals:TodoFormLocals):HtmlNode {
		return <form_with url=${Routes.todosPath()} scope=${Todo.railsParamKey} local class=${TodoHooks.formClass} data-turbo="false">
			<hidden_field name=${Todo.f.userId} value=${locals.sampleUserId} />
			<div>
				<field_label name=${Todo.f.title}>What should ship next?</field_label>
				<text_field name=${Todo.f.title} placeholder="Write the HHX form DSL" required />
			</div>
			<div>
				<field_label name=${Todo.f.notes}>Why does it matter?</field_label>
				<text_area name=${Todo.f.notes} placeholder="Add a short implementation note" rows=${3} />
			</div>
			<submit type="submit">Add task</submit>
		</form_with>;
	}
}
