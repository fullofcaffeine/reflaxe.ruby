package routes;

import controllers.HealthController;
import controllers.PostsController;
import controllers.ProfilesController;
import controllers.admin.PostsController as AdminPostsController;
import models.Post;
import models.Profile;
import rails.macros.RoutesDsl.*;

// Haxe-owned routes are source-of-truth for this fixture. The compiler checks
// typed controller/action refs, checked route names/paths/constants, and then
// emits ordinary Rails config/routes.rb plus a route manifest for parity checks.
@:railsRoutes
class AppRoutes {
	static final routes = {
		root(to(PostsController, index));
		// Direct verb routes demonstrate typed targets plus checked route names.
		get("posts/archive", to(PostsController, archive), {asName: routeName("archived_posts")});
		post("posts", to(PostsController, create));
		match("posts/search", to(PostsController, search), [GET, POST], {asName: routeName("post_search")});
		// Rails path features stay string-shaped because Rails owns the syntax,
		// but RailsHx parses/checks literals for optional and glob segment safety.
		get("photos(/:id)", to(PostsController, showOptional), {asName: routeName("photo_display")});
		get("files/*path", to(PostsController, file), {asName: routeName("file")});
		// Adoption seams can use checked external controller targets while still
		// emitting hand-written-looking Rails routes.
		get("legacy/posts/:id", externalTo("legacy/posts#show"), {asName: routeName("legacy_post")});
		// Mounted Rack apps are explicit Ruby constants so arbitrary Ruby route
		// code does not sneak into canonical typed examples.
		mountExternal(rubyConst("Sidekiq::Web"), at("/sidekiq"), {asName: routeName("sidekiq")});
		defaults({format: "json"}, {
			constraints({id: rx("[0-9]+")}, {
				get("numeric_posts/:id", to(PostsController, show), {asName: routeName("numeric_post")});
			});
		});
		resources(Post, PostsController, {except: [destroy], param: paramName("slug")}, {
			collection({
				get("archived", to(PostsController, archive), {asName: routeName("archived_collection")});
			});
			member({
				patch("publish", to(PostsController, publish), {asName: routeName("publish_post")});
			});
		});
		// This covers the @:native("new") mapping from Haxe newAction to Rails :new.
		resources(resourceName("draft_posts"), PostsController, {only: [newAction]});
		resource(Profile, ProfilesController, {only: [show, update]});
		namespace("admin", {
			get("posts/audit", to(AdminPostsController, audit), {asName: routeName("admin_post_audit")});
		});
		scope("/api", {moduleName: "api", asName: routeName("api")}, {
			get("status", to(HealthController, show), {asName: routeName("status")});
		});
		controller(HealthController, {
			get("up", to(HealthController, show), {asName: routeName("health")});
		});
	};
}
