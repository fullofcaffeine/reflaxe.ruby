package views;

import models.User;
import rails.action_view.HtmlNode;
import rails.action_view.Template;
import views.TodoFormView.TodoFormLocals;

typedef TodoComposerLocals = {
	var sampleUser:Null<User>;
}

// Conditional typed partial composer.
//
// Demonstrates: HHX `<if>/<else>` control flow and typed partial rendering.
// Type safety: `sampleUser` is `Null<User>`, so the null check narrows access to
// `locals.sampleUser.id`; `Template.of(TodoFormView)` checks the target partial
// and `TodoFormLocals` checks the locals object.
// IntelliSense: editors should complete `sampleUser`, `id`, `Template.of`, and
// the `sampleUserId` local required by `TodoFormView`.
// Ruby/Rails output: a Rails partial with conditional ERB and a normal
// `render partial:` call.
@:railsTemplate("controllers/todos/_composer")
@:railsTemplateAst("render")
class TodoComposerView {
	public static function render(locals:TodoComposerLocals):HtmlNode {
		return <if ${locals.sampleUser != null}>
			<partial template=${(Template.of(TodoFormView) : Template<TodoFormLocals>)} locals=${{sampleUserId: locals.sampleUser.id}} />
		<else>
			<div class="empty-state">
				Create a user first; the integration fixture seeds one before exercising this page.
			</div>
		</if>;
	}
}
