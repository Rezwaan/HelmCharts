class RushDeliveries::RushDeliveryService
  def create(attributes:)
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)

    rush_delivery = RushDeliveries::RushDelivery.new
    rush_delivery.drop_off_longitude = attributes[:drop_off_longitude]
    rush_delivery.drop_off_latitude = attributes[:drop_off_latitude]
    rush_delivery.drop_off_description = attributes[:drop_off_description]
    rush_delivery.pick_up_longitude = attributes[:pick_up_longitude]
    rush_delivery.pick_up_latitude = attributes[:pick_up_latitude]
    rush_delivery.order_id = attributes[:order_id]

    if rush_delivery.save!
      RushDeliveries::Pace::Workers::PaceOrderCreator.perform_async(rush_delivery.id)
    end

    rush_delivery
  end
end
