  # Rails-owned route fixture.
  #
  # This block deliberately stays outside `src/routes/AppRoutes.hx` to
  # model an existing Rails app route that a team does not want RailsHx to own
  # yet. The route is still visible to Haxe because RailsHx can run
  # `bin/rails routes`, generate `src/routes/Routes.hx`, and expose the
  # helper as the typed `Routes.legacyHealthPath()` method.
  #
  # In a real adopted Rails app, this line would already live in
  # `config/routes.rb`; the todoapp materializer splices it in only because the
  # generated Rails app is disposable.
  get "/rails-owned-health",
    to: proc { [200, { "Content-Type" => "text/plain" }, ["rails-owned route\n"]] },
    as: :legacy_health

  mount ActionCable.server => "/cable"
