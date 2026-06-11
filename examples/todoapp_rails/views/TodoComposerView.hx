package views;

import models.User;
import rails.action_view.HtmlNode;
import rails.action_view.Template;
import views.TodoFormView.TodoFormLocals;

typedef TodoComposerLocals = {
	var sampleUser:Null<User>;
}

@:railsTemplate("controllers/todos/_composer")
@:railsTemplateAst("render")
class TodoComposerView {
	public static function render(locals:TodoComposerLocals):HtmlNode {
		return <if ${locals.sampleUser != null}>
			<partial template=${(Template.named("controllers/todos/typed_form") : Template<TodoFormLocals>)} locals=${{sampleUserId: locals.sampleUser.id}} />
		<else>
			<div class="empty-state">
				Create a user first; the integration fixture seeds one before exercising this page.
			</div>
		</if>;
	}
}
