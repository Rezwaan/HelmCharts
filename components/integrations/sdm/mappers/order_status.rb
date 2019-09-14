class Integrations::Sdm::Mappers::OrderStatus
  STATUSES = [
    {id: 0, sdm: "Initial", dome: :accepted_by_store},
    {id: 1, sdm: "Open", dome: :accepted_by_store},
    {id: 2, sdm: "In Kitchen", dome: :accepted_by_store},
    {id: 4, sdm: "Bumped", dome: :accepted_by_store},
    {id: 8, sdm: "Ready", dome: :accepted_by_store},
    {id: 16, sdm: "Assigned", dome: :out_for_delivery},
    {id: 32, sdm: "Enroute", dome: :out_for_delivery},
    {id: 64, sdm: "Delivered", dome: :out_for_delivery},
    {id: 96, sdm: "Suspended", dome: :cancelled_by_store},
    {id: 100, sdm: "Future", dome: :accepted_by_store},
    {id: 128, sdm: "Closed", dome: :out_for_delivery},
    {id: 256, sdm: "Failure", dome: :cancelled_by_store},
    {id: 512, sdm: "Canceled", dome: :cancelled_by_store},
    {id: 1024, sdm: "Unknown", dome: :cancelled_by_store},
    {id: 2048, sdm: "Force Closed", dome: :out_for_delivery},
    {id: 4096, sdm: "Request for cancel", dome: :cancelled_by_store},
    {id: 8192, sdm: "Force Cancel", dome: :cancelled_by_store},
  ]

  class << self
    def failed?(status)
      [:cancelled_by_store].include?(mapped_status(status))
    end

    def mapped_status(sdm_status)
      sdm_status = sdm_status.to_i
      status = STATUSES.find { |st| st[:id] == sdm_status }

      status&.dig(:dome)
    end
  end
end
