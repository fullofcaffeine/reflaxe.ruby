package views;

import models.User;
import rails.action_view.HtmlNode;
import rails.action_view.Template;
import views.TodoFormView.TodoFormLocals;

typedef TodoComposerLocals = {
	var currentUser:User;
}

// Conditional typed partial composer.
//
// Demonstrates: typed partial rendering without leaking ownership fields into
// the browser. The controller adds `current_user.id` after strong params, while
// the UI can still explain which user owns the new task.
// Type safety: `Template.of(TodoFormView)` checks the target partial and
// `TodoFormLocals` checks the locals object.
// IntelliSense: editors should complete `Template.of` and form-local fields.
// Ruby/Rails output: a Rails partial render plus a normal Rails form.
@:railsTemplate("todos/_composer")
@:railsTemplateAst("render")
class TodoComposerView {
	public static function render(locals:TodoComposerLocals):HtmlNode {
		return <><partial template=${(Template.of(TodoFormView) : Template<TodoFormLocals>)} locals=${{currentUserName: locals.currentUser.name}} /></>;
	}
}
