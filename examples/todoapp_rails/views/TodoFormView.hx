package views;

import rails.action_view.HtmlNode;
import routes.Routes;

typedef TodoFormLocals = {
	var sampleUserId:Int;
}

@:railsTemplate("controllers/todos/_typed_form")
@:railsTemplateAst("render")
class TodoFormView {
	public static function render(locals:TodoFormLocals):HtmlNode {
		return <form_with url=${Routes.todosPath()} scope="todo" local class="todo-form">
			<hidden_field name="user_id" value=${locals.sampleUserId} />
			<div>
				<field_label name="title">What should ship next?</field_label>
				<text_field name="title" placeholder="Write the HHX form DSL" required />
			</div>
			<div>
				<field_label name="notes">Why does it matter?</field_label>
				<text_area name="notes" placeholder="Add a short implementation note" rows=${3} />
			</div>
			<div class="form-check">
				<check_box name="is_completed" />
				<field_label name="is_completed">Already done?</field_label>
			</div>
			<submit type="submit">Add task</submit>
		</form_with>;
	}
}
