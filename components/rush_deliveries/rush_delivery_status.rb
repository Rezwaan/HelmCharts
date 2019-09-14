class RushDeliveries::RushDeliveryStatus
  STATUSES = %w[unassigned assigned
                enroute_to_branch at_the_branch picked_up enroute_to_customer delivered
                canceled failed_to_assign near_pick_up near_delivery left_pick_up
                pre_assigned returned waiting_pickup_confirmation pickup_confirmed
                at_delivery left_delivery].freeze

  def initialize(status)
    @status = status
  end

  def to_s
    @status.to_s
  end

  class << self
    def enum_hash
      Hash[STATUSES.map { |el| [el, el] }]
    end
  end
end
