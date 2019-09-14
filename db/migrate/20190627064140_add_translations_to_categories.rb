class AddTranslationsToCategories < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        Brands::Categories::BrandCategory.create_translation_table!({
          name: :string,
          plural_name: :string,
        }, {
          migrate_data: true,
        })
      end

      dir.down do
        Brands::Categories::BrandCategory.drop_translation_table! migrate_data: true
      end
    end
  end
end
