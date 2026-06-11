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
			<hidden_field name="is_completed" value=${false} />
			<div>
				<field_label name="title">What should ship next?</field_label>
				<text_field name="title" placeholder="Write the HHX form DSL" required />
			</div>
			<submit type="submit">Add task</submit>
		</form_with>;
	}
}
