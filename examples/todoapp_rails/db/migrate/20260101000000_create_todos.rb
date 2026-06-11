# Demo migration template for examples/todoapp_rails.
class CreateTodos < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :todos do |t|
      t.string :title, null: false
      t.text :notes, null: false, default: ""
      t.boolean :is_completed, null: false, default: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
