class RenameIntegrationType < ActiveRecord::Migration[5.2]
  def change
    rename_column :integration_hosts, :integrattion_type, :integration_type
  end
end
