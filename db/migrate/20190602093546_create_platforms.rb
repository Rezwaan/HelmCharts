class CreatePlatforms < ActiveRecord::Migration[5.2]
  def change
    create_table :platforms do |t|
      t.string :backend_id, unique: true, null: false
      t.string :logo_url

      t.timestamps
    end
  end
end
