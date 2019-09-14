module Integrations
  module Br
    module Serializers
      class OrderStatusSerializer
        attr_reader :order_status

        def initialize(order_status:)
          @order_status = order_status
        end

        def serialize
          get_entries_from_xml.inject({}) do |hash, entry|
            hash = {
              order_code: entry.children[0].text,
              customer_code: entry.children[1].text,
              status: entry.children[2].text,
            }

            hash
          end
        end

        private

        def get_entries_from_xml
          order_status.xpath("//*[starts-with(local-name(), 'Entry')]")
        end
      end
    end
  end
end
