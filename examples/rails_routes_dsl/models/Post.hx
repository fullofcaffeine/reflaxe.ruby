package models;

// The routing DSL can derive the Rails resource name from typed model metadata,
// so app code writes `resources(Post, ...)` instead of repeating "posts".
@:railsModel("posts")
class Post extends rails.active_record.Base<Post> {}
