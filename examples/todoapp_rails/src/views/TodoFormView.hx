package views;

import models.Todo;
import rails.action_view.HtmlNode;
import routes.Routes;
import shared.TodoHooks;

typedef TodoFormLocals = {
	var currentUserName:String;
}

// Typed Rails form partial.
//
// Demonstrates: Rails form helpers authored as HHX tags and backed by typed
// model field refs.
// Type safety: `Todo.railsParamKey` supplies the form scope; `Todo.f.title` and
// `Todo.f.notes` are generated field refs, so renamed/missing model fields fail
// in Haxe instead of becoming broken Rails params. The controller adds
// `current_user.id` server-side, so this form does not carry spoofable user ids.
// IntelliSense: editors should complete `Todo.f.*`, `Routes.todosPath`, and the
// `currentUserName` local.
// Ruby/Rails output: normal Rails form builder ERB with strong Rails param names.
// Field errors are read from Rails' ActiveModel errors collection at runtime;
// Haxe still checks the model-owned field ref before emitting `errors[:field]`.
@:railsTemplate("todos/_typed_form")
@:railsTemplateAst("render")
class TodoFormView {
	public static function render(locals:TodoFormLocals):HtmlNode {
		return <form_with url=${Routes.todosPath()} scope=${Todo.railsParamKey} local class=${TodoHooks.formClass}>
			<p class="form-owner-note">New tasks will be assigned to ${locals.currentUserName}.</p>
			<div>
				<field_label name=${Todo.f.title}>What should ship next?</field_label>
				<search_field name=${Todo.f.title} placeholder="Write the HHX form DSL" required />
				<field_errors name=${Todo.f.title} class="field-error" aria-live="polite" />
			</div>
			<div>
				<field_label name=${Todo.f.notes}>Why does it matter?</field_label>
				<text_area name=${Todo.f.notes} placeholder="Add a short implementation note" rows=${3} />
				<field_errors name=${Todo.f.notes} class="field-error" />
			</div>
			<submit type="submit">Add task</submit>
		</form_with>;
	}
}
