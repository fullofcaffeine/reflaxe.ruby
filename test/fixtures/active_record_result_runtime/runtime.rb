# Executes compiler-generated result adapters against real in-memory ActiveRecord.
output_root = File.expand_path(ARGV.fetch(0))

require "active_record"
require "sqlite3"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Schema.verbose = false

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

ActiveRecord::Schema.define do
  create_table :users do |table|
    table.string :name, null: false
  end

  create_table :todos do |table|
    table.string :title, null: false
    table.boolean :completed, null: false, default: false
    table.string :status, null: false, default: "open"
    table.text :notes
    table.string :external_id, null: false
    table.integer :user_id, null: false
  end
end

require File.join(output_root, "app/lib/railshx/runtime/hxruby/core")
require File.join(output_root, "app/lib/railshx/runtime/hxruby/maps")
require File.join(output_root, "app/models/user")
require File.join(output_root, "app/models/todo")
require File.join(output_root, "app/lib/railshx/generated/active_record_result_runtime_main")

owner = User.create!(name: "owner")
reader = User.create!(name: "reader")
Todo.create!(title: "alpha", status: "open", external_id: "alpha-1", user_id: owner.id)
Todo.create!(title: "beta", status: "open", external_id: "beta-1", user_id: reader.id)
Todo.create!(title: "gamma", status: "done", external_id: "gamma-1", user_id: owner.id)

ActiveRecordResultRuntimeMain.main
# The ABI must not expose its Ruby implementation mixin as a Haxe superclass.
puts(Haxe::Ds::StringMap.superclass == Object && Haxe::Ds::IntMap.superclass == Object)
