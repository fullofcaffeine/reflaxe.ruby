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
		var appendLocals:TodoRowLocals = {
			domId: "todo_1",
			title: "Ship typed Turbo Streams",
			completed: false
		};
		var replaceLocals:TodoRowLocals = {
			domId: "todo_1",
			title: "Ship typed Turbo Streams, but polished",
			completed: true
		};
		var dynamicLocals:Dynamic = appendLocals;

		// Demonstrates: Rails view/controller-context stream rendering. The output
		// is `turbo_stream.append(...)`, not a RailsHx runtime helper. Prebuilt
		// typed locals values are projected into snake_case Rails locals hashes.
		TurboStreams.append(TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), appendLocals);

		// Demonstrates: same typed partial/locals contract for another Rails
		// stream action.
		TurboStreams.replace(TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), replaceLocals);

		// Demonstrates: inline object literals still lower directly to Rails
		// snake_case locals without needing an intermediate value.
		TurboStreams.update(TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), {
			domId: "todo_2",
			title: "Inline locals still work",
			completed: false
		});

		// Demonstrates: dynamic locals stay explicit pass-through values. This is
		// the escape hatch for Ruby/Rails-owned runtime hashes.
		TurboStreams.prepend(TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), dynamicLocals);

		// Demonstrates: positional insert actions map to normal
		// `turbo_stream.before/after(...)` helpers.
		TurboStreams.before(TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), {
			domId: "todo_before",
			title: "Inserted before the list",
			completed: false
		});
		TurboStreams.after(TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), {
			domId: "todo_after",
			title: "Inserted after the list",
			completed: false
		});

		// Demonstrates: remove only needs the typed DOM target.
		TurboStreams.remove(TodoStreams.listTarget);

		// Demonstrates: server-side broadcast lowering to the Rails Turbo channel
		// helper while preserving the same typed target/template/locals contract.
		TurboStreams.broadcastAppendTo(TodoStreams.listStream, TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), appendLocals);
		TurboStreams.broadcastPrependTo(TodoStreams.listStream, TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), appendLocals);
		TurboStreams.broadcastBeforeTo(TodoStreams.listStream, TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), appendLocals);
		TurboStreams.broadcastAfterTo(TodoStreams.listStream, TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), appendLocals);
		TurboStreams.broadcastReplaceTo(TodoStreams.listStream, TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), replaceLocals);
		TurboStreams.broadcastUpdateTo(TodoStreams.listStream, TodoStreams.listTarget, (Template.of(TodoRowView) : Template<TodoRowLocals>), replaceLocals);
		TurboStreams.broadcastRemoveTo(TodoStreams.listStream, TodoStreams.listTarget);
	}
}
