package views;

import models.Todo;
import rails.action_view.HtmlNode;
import routes.Routes;

typedef TodoFormLocals = {
	var sampleUserId:Int;
}

@:railsTemplate("controllers/todos/_typed_form")
@:railsTemplateAst("render")
class TodoFormView {
	public static function render(locals:TodoFormLocals):HtmlNode {
		return <form_with url=${Routes.todosPath()} scope=${Todo.railsParamKey} local class="todo-form">
			<hidden_field name=${Todo.userIdField} value=${locals.sampleUserId} />
			<div>
				<field_label name=${Todo.titleField}>What should ship next?</field_label>
				<text_field name=${Todo.titleField} placeholder="Write the HHX form DSL" required />
			</div>
			<div>
				<field_label name=${Todo.notesField}>Why does it matter?</field_label>
				<text_area name=${Todo.notesField} placeholder="Add a short implementation note" rows=${3} />
			</div>
			<submit type="submit">Add task</submit>
		</form_with>;
	}
}
