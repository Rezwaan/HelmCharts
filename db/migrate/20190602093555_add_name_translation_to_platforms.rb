class AddNameTranslationToPlatforms < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        Platforms::Platform.create_translation_table!({
          name: :text,
        }, {
          migrate_data: true,
        })
      end

      dir.down do
        Platforms::Platform.drop_translation_table! migrate_data: true
      end
    end
  end
end
