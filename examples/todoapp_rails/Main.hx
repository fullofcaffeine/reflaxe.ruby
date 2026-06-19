import app.auth.UserAuth;
import controllers.ChatMessagesController;
import controllers.SessionsController;
import controllers.TodosController;
import controllers.UsersController;
import migrations.AddDeviseToUsers;
import migrations.CreateChatMessages;
import migrations.CreateTodos;
import migrations.UpdateTodos;
import migrations.UpdateUsers;
import models.ChatMessage;
import models.Todo;
import routes.AppRoutes;
import test_haxe.models.TodoHaxeTest;
import views.ApplicationLayoutView;
import views.AppTopBarView;
import views.ChatMessageView;
import views.ChatPanelView;
import views.DeviseLoginView;
import views.TodoCardView;
import views.TodoComposerView;
import views.TodoDashboardView;
import views.TodoFormView;
import views.TodoIndexView;
import views.TodoListView;
import views.TodoSummaryView;
import views.UserManagementView;

// RailsHx todoapp compile sentinel.
//
// Demonstrates: the end-to-end app graph compiles: models, migrations,
// controller, layout, and all HHX views.
// Type safety: each imported class must resolve through Haxe, so renaming a view
// or migration breaks the compile before Rails receives stale generated files.
// The Haxe-authored Rails test import proves generated test artifacts are also
// in the compile graph without being emitted into app autoload paths.
// IntelliSense: editors should complete the full app surface from Haxe packages.
// Ruby/Rails output: generated Rails app artifacts under the configured output
// root plus ActionView templates and migrations.
class Main {
	static function main() {
		var todo:Todo = null;
		var chatMessage:ChatMessage = null;
		var userAuth:Class<UserAuth> = UserAuth;
		var routes:Class<AppRoutes> = null;
		var haxeAuthoredTest:Class<TodoHaxeTest> = TodoHaxeTest;
		var deviseMigration:Class<AddDeviseToUsers> = AddDeviseToUsers;
		var chatMigration:Class<CreateChatMessages> = CreateChatMessages;
		var migration:Class<CreateTodos> = CreateTodos;
		var updateMigration:Class<UpdateTodos> = UpdateTodos;
		var userMigration:Class<UpdateUsers> = UpdateUsers;
		var chatController:ChatMessagesController = null;
		var controller:TodosController = null;
		var sessionsController:SessionsController = null;
		var userController:UsersController = null;
		var chatMessageView:Class<ChatMessageView> = ChatMessageView;
		var chatPanelView:Class<ChatPanelView> = ChatPanelView;
		var deviseLoginView:Class<DeviseLoginView> = DeviseLoginView;
		var layoutView:Class<ApplicationLayoutView> = ApplicationLayoutView;
		var topBarView:Class<AppTopBarView> = AppTopBarView;
		var cardView:Class<TodoCardView> = TodoCardView;
		var composerView:Class<TodoComposerView> = TodoComposerView;
		var dashboardView:Class<TodoDashboardView> = TodoDashboardView;
		var formView:Class<TodoFormView> = TodoFormView;
		var listView:Class<TodoListView> = TodoListView;
		var view:Class<TodoIndexView> = TodoIndexView;
		var summaryView:Class<TodoSummaryView> = TodoSummaryView;
		var userManagementView:Class<UserManagementView> = UserManagementView;
		Sys.println(todo == null);
		Sys.println(chatMessage == null);
		Sys.println(userAuth != null);
		Sys.println(routes == null);
		Sys.println(haxeAuthoredTest != null);
		Sys.println(deviseMigration != null);
		Sys.println(chatMigration != null);
		Sys.println(migration != null);
		Sys.println(updateMigration != null);
		Sys.println(userMigration != null);
		Sys.println(chatController == null);
		Sys.println(controller == null);
		Sys.println(sessionsController == null);
		Sys.println(userController == null);
		Sys.println(chatMessageView != null);
		Sys.println(chatPanelView != null);
		Sys.println(deviseLoginView != null);
		Sys.println(layoutView != null);
		Sys.println(topBarView != null);
		Sys.println(cardView != null);
		Sys.println(composerView != null);
		Sys.println(dashboardView != null);
		Sys.println(formView != null);
		Sys.println(listView != null);
		Sys.println(view != null);
		Sys.println(summaryView != null);
		Sys.println(userManagementView != null);
	}
}
