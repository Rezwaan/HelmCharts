class AddIntegrationStoreIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :integration_stores, [:integration_host_id, :external_reference], unique: true, name: "integration_stores_external_reference_uniqness"
  end
end
