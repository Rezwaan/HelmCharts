class CreateWeekWorkingTimes < ActiveRecord::Migration[5.2]
  def change
    create_table :week_working_times, id: :uuid do |t|
      t.references :working_time_rule, foreign_key: true, index: true, type: :uuid
      t.integer :weekday, null: false
      t.integer :start_from_minutes, null: false
      t.integer :end_at_minutes, null: false

      t.timestamps
    end
  end
end
