class CreateCountry < ActiveRecord::Migration[5.2]
  def change
    create_table :countries do |t|
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Countries::Country.create_translation_table! name: :string
      end

      dir.down do
        Countries::Country.drop_translation_table!
      end
    end
  end
end
