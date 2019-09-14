class AddColumnDescriptionWithTranslationToStores < ActiveRecord::Migration[5.2]
  def up
    Stores::Store.add_translation_fields! description: :text
  end

  def down
    remove_column :store_translations, :description
  end
end
