class Common::Sidekiq
  include Sidekiq::Worker

  def call(worker_class, job, queue, redis_pool)
    return false if worker_class.in?(disabled_workers)

    yield
  end

  def disabled_workers
    Rails.application.secrets.dig(:sidekiq, :disabled_workers).to_s.split(/[\n\r ]/)
  end
end
