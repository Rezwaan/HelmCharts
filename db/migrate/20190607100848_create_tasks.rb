class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks, id: :uuid do |t|
      t.references :store, foreign_key: true, index: true, null: false
      t.integer :task_type, null: false
      t.integer :status, null: false, default: 1
      t.references :related_to, polymorphic: true, index: false
      t.timestamp :expiry_at, :timestamp, default: nil, null: true
      t.timestamps
    end
  end
end
