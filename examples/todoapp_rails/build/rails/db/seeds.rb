owner = Models::User.find_or_create_by!(email: "owner@example.test") do |user|
  user.name = "RailsHx Owner"
  user.role = "admin"
  user.password = "password123"
  user.password_confirmation = "password123"
end

maintainer = Models::User.find_or_create_by!(email: "maintainer@example.test") do |user|
  user.name = "Template Maintainer"
  user.role = "maintainer"
  user.password = "password123"
  user.password_confirmation = "password123"
end

member = Models::User.find_or_create_by!(email: "member@example.test") do |user|
  user.name = "Product Member"
  user.role = "member"
  user.password = "password123"
  user.password_confirmation = "password123"
end

guest = Models::User.find_or_create_by!(email: "guest@example.test") do |user|
  user.name = "Guest Workspace"
  user.role = "guest"
  user.password = "password123"
  user.password_confirmation = "password123"
end

Models::Todo.find_or_create_by!(title: "Ship typed Rails templates", user: owner) do |todo|
  todo.notes = "HHX stays typed in Haxe; ERB is generated for Rails."
  todo.is_completed = false
end

Models::Todo.find_or_create_by!(title: "Wire the Rails dev loop", user: maintainer) do |todo|
  todo.notes = "Compile Haxe, run Rails, keep the watcher nearby."
  todo.is_completed = false
end

Models::Todo.find_or_create_by!(title: "Model a typed session seam", user: member) do |todo|
  todo.notes = "Use Rails session and flash stores through typed Haxe facades."
  todo.is_completed = false
end

Models::ChatMessage.find_or_create_by!(body: "Routes, params, and HHX are all typed for this room.", user: owner)
Models::ChatMessage.find_or_create_by!(body: "Turbo gets normal Rails streams; Haxe owns the safer authoring layer.", user: maintainer)
Models::ChatMessage.find_or_create_by!(body: "Turbo Streams carry typed room updates between browsers.", user: member)
Models::ChatMessage.find_or_create_by!(body: "Guest mode is Devise-backed; Haxe just makes the happy path typed.", user: guest)
