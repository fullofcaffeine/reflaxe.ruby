import rails.action_view.Template;
import rails.turbo.StreamName;
import rails.turbo.StreamTarget;
import rails.turbo.TurboStreams;
import views.TodoRowView;
import views.TodoRowView.TodoRowLocals;

class TodoStreams {
	// Demonstrates: central typed stream targets instead of repeating app-level
	// string literals. The values still lower to Rails' normal DOM target names.
	public static inline var listTarget:StreamTarget = "todos";

	// Demonstrates: a stream name carrying the payload/locals shape used by
	// broadcasts. Passing a locals object without `completed` will fail in Haxe.
	public static inline var listStream:StreamName<TodoRowLocals> = "todos";
}

class Main {
	static function main():Void {
		// Demonstrates: Rails view/controller-context stream rendering. The output
		// is `turbo_stream.append(...)`, not a RailsHx runtime helper.
		TurboStreams.append(TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), {
			domId: "todo_1",
			title: "Ship typed Turbo Streams",
			completed: false
		});

		// Demonstrates: same typed partial/locals contract for another Rails
		// stream action.
		TurboStreams.replace(TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), {
			domId: "todo_1",
			title: "Ship typed Turbo Streams, but polished",
			completed: true
		});

		// Demonstrates: remove only needs the typed DOM target.
		TurboStreams.remove(TodoStreams.listTarget);

		// Demonstrates: server-side broadcast lowering to the Rails Turbo channel
		// helper while preserving the same typed target/template/locals contract.
		TurboStreams.broadcastAppendTo(TodoStreams.listStream, TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), {
			domId: "todo_1",
			title: "Ship typed Turbo Streams",
			completed: false
		});
	}
}
