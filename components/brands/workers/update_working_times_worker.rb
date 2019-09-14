class Brands::Workers::UpdateWorkingTimesWorker
  include Sidekiq::Worker

  def perform(id, data)
    Stores::StoreService.new.publish_pubsub_by_brand(brand_id: id, data: data)
  end
end
