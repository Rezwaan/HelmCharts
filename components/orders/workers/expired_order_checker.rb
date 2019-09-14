class Orders::Workers::ExpiredOrderChecker
  include Sidekiq::Worker
  def perform
    all_platforms = Platforms::PlatformService.new.filter(per_page: nil)
    all_platforms.each do |platform|
      expiry_minutes = platform_expiry(platform_id: platform.id)
      prayer_time_exception = platform_prayer_time_exception(platform_id: platform.id)
      Orders::OrderService.new.cancel_expired_order(platform_id: platform.id, expiry_minutes: expiry_minutes, prayer_time_exception: prayer_time_exception)
    end
  end

  # @TODO: Allow per platform/country/zone configuration
  def platform_expiry(platform_id:, country_id: nil)
    Rails.application.secrets.orders&.dig(:expiry, :expiry_minutes) || 10
  end

  def platform_prayer_time_exception(platform_id:, country_id: nil)
    Rails.application.secrets.orders&.dig(:expiry, :prayer_time_exception) || false
  end
end
