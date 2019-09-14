class CreateCatalogAssignments < ActiveRecord::Migration[5.2]
  def change
    create_table :catalog_assignments, id: :uuid do |t|
      t.references :catalog, foreign_key: true, index: true, type: :uuid
      t.references :related_to, polymorphic: true, uniq: true
      t.timestamps
    end
  end
end
