package migrations;

import models.Todo;
import models.User;
import rails.migration.Migration;

// Initial typed Rails migration.
//
// Demonstrates: deriving Rails `create_table` migrations from typed model
// metadata instead of hand-writing Ruby migration source.
// Type safety: model paths must resolve to Haxe classes annotated with
// `@:railsModel`; bad paths or non-model classes fail at compile time.
// IntelliSense: editors should complete `models.User`, `models.Todo`, and the
// migration metadata fields.
// Ruby/Rails output: a timestamped ActiveRecord migration file.
@:railsMigration({
	timestamp: "20260101000000",
	className: "CreateTodos",
	models: ["models.User", "models.Todo"]
})
class CreateTodos extends Migration {
	static final userModel:Class<User> = User;
	static final todoModel:Class<Todo> = Todo;
}
