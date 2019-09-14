class AddTranslationToCompany < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        Companies::Company.create_translation_table! name: :string
      end

      dir.down do
        Companies::Company.drop_translation_table!
      end
    end
  end
end
