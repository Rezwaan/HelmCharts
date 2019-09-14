class Zendesk::Workers::UserCreatorWorker
  include Sidekiq::Worker

  def perform(account_id)
    Zendesk::UserService.new.find_or_create(account_id: account_id)
  end
end
