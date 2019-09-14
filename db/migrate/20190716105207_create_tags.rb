class CreateTags < ActiveRecord::Migration[5.2]
  def change
    create_table :tags, id: :uuid do |t|
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Tags::Tag.create_translation_table! name: :string
      end

      dir.down do
        Tags::Tag.drop_translation_table!
      end
    end
  end
end
