module Integrations
  module Br
    module Params
      class OrderStatusParams
        attr_reader :integration_order

        def initialize(integration_order:)
          @integration_order = integration_order
        end

        def build
          Nokogiri::XML::Builder.new do |xml|
            xml.Envelope('xmlns:soap': "http://schemas.xmlsoap.org/soap/envelope/", 'xmlns:xsd': "http://www.w3.org/2001/XMLSchema") do
              xml.parent.namespace = xml.parent.namespace_definitions.first

              xml["soap"].Body do
                xml.HDUE_ORDERSTATUS do
                  xml.OCODE integration_order.external_reference
                end
              end
            end
          end
        end
      end
    end
  end
end
