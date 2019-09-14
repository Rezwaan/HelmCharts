class RushDeliveries::Pace::Workers::PaceOrderCreator
  include Sidekiq::Worker

  sidekiq_options retry: 3

  def perform(rush_delivery_id)
    rush_delivery = RushDeliveries::RushDelivery.find(rush_delivery_id)

    pace_order = RushDeliveries::Pace::Helpers::OrderCreator.new.generate_order(rush_delivery)

    RushDeliveries::Pace::PaceService.new.submit_order(order: pace_order)
  end
end
