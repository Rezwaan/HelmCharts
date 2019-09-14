class StoreItemAvailabilities::Workers::RemoveExpiredStoreItemsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    StoreItemAvailabilities::StoreItemAvailabilityService.new.remove_expired
  end
end
