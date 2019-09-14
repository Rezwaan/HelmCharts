class AddNameTranslationToBrands < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        Brands::Brand.create_translation_table!({
          name: :text,
        }, {
          migrate_data: true,
        })
      end

      dir.down do
        Brands::Brand.drop_translation_table! migrate_data: true
      end
    end
  end
end
