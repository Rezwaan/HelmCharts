class Stores::Workers::ReopenStoresWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    Stores::StoreStatusService.new.reopen_busy_stores
  end
end
