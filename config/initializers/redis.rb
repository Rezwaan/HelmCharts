require "connection_pool"

$redis = ConnectionPool.new(size: 10) {
  Redis.new(url: Rails.application.secrets.store_status[:redis_uri])
}
