package migrations;

import models.Todo;
import models.User;
import rails.migration.Migration;

@:railsMigration({
	timestamp: "20260101000000",
	className: "CreateTodos",
	models: ["models.User", "models.Todo"]
})
class CreateTodos extends Migration {
	static final userModel:Class<User> = User;
	static final todoModel:Class<Todo> = Todo;
}
