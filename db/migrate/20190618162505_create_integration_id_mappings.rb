class CreateIntegrationIdMappings < ActiveRecord::Migration[5.2]
  def change
    create_table :integration_id_mappings, id: :bigint do |t|
      t.text :str, index: {unique: true}, null: false

      t.timestamps
    end
  end
end
