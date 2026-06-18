import routes.AppRoutes;

class Main {
	static function main() {
		// This fixture exists for compiler snapshots: importing AppRoutes forces
		// the @:railsRoutes class to be compiled, but no runtime router object is
		// emitted. Rails receives a normal config/routes.rb artifact instead.
		var routes:Class<AppRoutes> = AppRoutes;
		Sys.println(routes != null);
	}
}
