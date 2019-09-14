class CreateWorkingTimeRules < ActiveRecord::Migration[5.2]
  def change
    create_table :working_time_rules, id: :uuid do |t|
      t.string :name
      t.timestamps
    end
  end
end
