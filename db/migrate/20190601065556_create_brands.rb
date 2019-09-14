class CreateBrands < ActiveRecord::Migration[5.2]
  def change
    create_table :brands, id: :uuid do |t|
      t.string :backend_id, index: true
      t.string :name
    end
  end
end
