class AssignWorkingHours < ActiveRecord::Migration[5.2]
  def change
    create_table :working_time_rule_assignments, id: :uuid do |t|
      t.references :working_time_rule, foreign_key: true, index: true, type: :uuid
      t.references :related_to, polymorphic: true, index: {name: "index_working_time_rule_assignments_on_related_to"}
      t.timestamps
    end
  end
end
