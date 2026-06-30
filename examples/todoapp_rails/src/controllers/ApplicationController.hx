package controllers;

// Typed RailsHx base controller for the generated Rails app.
//
// Demonstrates: the Haxe equivalent of Rails' `ApplicationController`.
// Type safety: app controllers inherit RailsHx controller helpers through this
// single typed base instead of extending the raw ActionController facade.
// IntelliSense: editors should show controller helper methods from the shared
// base when authoring app controllers.
// Ruby/Rails output: `app/controllers/application_controller.rb` with
// `class ApplicationController < ActionController::Base`.
@:railsApplicationController
class ApplicationController extends rails.action_controller.Base {
	static final lifecycle = [];
}
