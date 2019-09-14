class CreateIntegrationHosts < ActiveRecord::Migration[5.2]
  def change
    create_table :integration_hosts, id: :uuid do |t|
      t.string :name
      t.jsonb :config
      t.integer :integrattion_type

      t.timestamps
    end
  end
end
