class AddOrderLineItemTranslations < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        Orders::OrderLineItem.create_translation_table!({
          name: :text,
          description: :text,
        }, {
          migrate_data: true,
        })
      end

      dir.down do
        Orders::OrderLineItem.drop_translation_table! migrate_data: true
      end
    end
    reversible do |dir|
      dir.up do
        Orders::OrderLineItemModifier.create_translation_table!({
          name: :text,
          group: :text,
        }, {
          migrate_data: true,
        })
      end

      dir.down do
        Orders::OrderLineItemModifier.drop_translation_table! migrate_data: true
      end
    end
  end
end
