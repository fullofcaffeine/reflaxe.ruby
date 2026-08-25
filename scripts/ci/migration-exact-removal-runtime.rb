# frozen_string_literal: true

# Proves that Rails can rebuild exact-removal definitions and that an explicit
# irreversible down branch raises Rails' native migration failure.
require File.expand_path("../../examples/todoapp_rails/build/rails/config/environment", __dir__)

generated_dir = File.expand_path("../../examples/todoapp_rails/tmp/smoke/migration_exact_removal_out/db/migrate", __dir__)
require File.join(generated_dir, "20260101000044_exact_removal_contract_migration")
require File.join(generated_dir, "20260101000045_irreversible_contract_migration")

connection = ActiveRecord::Base.connection

begin
  connection.drop_table(:widgets, if_exists: true)
  connection.drop_table(:owners, if_exists: true)
  connection.create_table(:owners)
  connection.create_table(:widgets) do |table|
    table.bigint :owner_id, null: false
    table.string :status, null: false
  end
  connection.add_index(:widgets, %i[owner_id status], unique: true, name: "index_widgets_owner_status")
  connection.add_foreign_key(:widgets, :owners, column: :owner_id, name: "fk_widgets_owners", on_delete: :cascade,
    deferrable: :deferred, validate: false)

  owner_id = connection.insert("INSERT INTO owners DEFAULT VALUES")
  connection.execute("INSERT INTO widgets (owner_id, status) VALUES (#{Integer(owner_id)}, 'active')")

  ExactRemovalContractMigration.migrate(:up)
  raise "exact index removal did not run" if connection.index_exists?(:widgets, %i[owner_id status], name: "index_widgets_owner_status")
  raise "exact foreign-key removal did not run" if connection.foreign_key_exists?(:widgets, :owners, name: "fk_widgets_owners")

  ExactRemovalContractMigration.migrate(:down)
  index = connection.indexes(:widgets).find { |candidate| candidate.name == "index_widgets_owner_status" }
  raise "rollback did not restore the named unique index" unless index&.unique && index.columns == %w[owner_id status]
  foreign_key = connection.foreign_keys(:widgets).find { |candidate| candidate.to_table == "owners" && candidate.options[:column] == "owner_id" }
  raise "rollback did not restore the cascading deferred foreign key" unless foreign_key&.on_delete == :cascade && foreign_key.deferrable == :deferred
  raise "migration changed existing rows" unless connection.select_value("SELECT COUNT(*) FROM widgets").to_i == 1

  IrreversibleContractMigration.migrate(:up)
  begin
    IrreversibleContractMigration.migrate(:down)
    raise "irreversible rollback unexpectedly succeeded"
  rescue ActiveRecord::IrreversibleMigration => error
    raise "irreversible rollback lost its reason" unless error.message.include?("deleted audit rows cannot be restored")
  end
ensure
  connection.drop_table(:widgets, if_exists: true)
  connection.drop_table(:owners, if_exists: true)
end

puts "migration exact-removal runtime contract passed"
