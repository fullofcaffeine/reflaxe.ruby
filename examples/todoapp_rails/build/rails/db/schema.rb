# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_01_01_000004) do
  create_table "chat_messages", force: :cascade do |t|
    t.text "body", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "id"], name: "index_chat_messages_on_user_id_and_id"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "todos", force: :cascade do |t|
    t.string "title", null: false
    t.text "notes", default: "", null: false
    t.boolean "is_completed", default: false, null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority", default: 0, null: false
    t.index ["priority"], name: "index_todos_on_priority"
    t.index ["title"], name: "index_todos_on_title"
    t.index ["user_id", "priority"], name: "index_todos_priority_by_user"
    t.index ["user_id"], name: "index_todos_on_user_id"
    t.check_constraint "priority >= 0", name: "chk_todos_priority_non_negative"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "owner@example.test", null: false
    t.string "role", default: "member", null: false
    t.string "encrypted_password", default: "", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "chat_messages", "users"
  add_foreign_key "todos", "users", deferrable: :deferred
  add_foreign_key "todos", "users", on_delete: :cascade, deferrable: :deferred
end
