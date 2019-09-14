class Stores::Workers::UpdateStoreAvailability
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    Stores::StoreStatusService.new.update_store_availability
  end
end
