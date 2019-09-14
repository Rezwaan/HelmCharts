module Integrations
  module Foodics
    module OrderType
      extend self

      # See:
      # https://dash.foodics.com/api-docs#list-order-tags
      ORDER_TYPES = {
        1 => {definition: :dine_in, deliverable: false},
        2 => {definition: :take_away, deliverable: false},
        3 => {definition: :pickup, deliverable: false},
        4 => {definition: :delivery, deliverable: true},
        5 => {definition: :drive_through, deliverable: false},
      }.freeze

      def deliverable_order_types
        ORDER_TYPES.select { |id, order_type|
          order_type[:deliverable]
        }.keys.to_a
      end
    end
  end
end
