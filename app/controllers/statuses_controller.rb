class StatusesController < ActionController::API
  def status
    statuses = prepare_statuses
    unless statuses[:dependecies].values.all?
      # 503 service unavailable response
      Rails.logger.info statuses
      return render json: statuses, status: :service_unavailable
    end

    render json: statuses
  end

  def readiness
    statuses = prepare_statuses
    unless statuses[:dependecies].values.all?
      # 503 service unavailable response
      Rails.logger.info statuses
      return render json: statuses, status: :service_unavailable
    end

    render json: statuses
  end

  def liveness
    render json: {status: "working"}
  end

  private

  def prepare_statuses
    {
      dependecies: {
        databsae: db_is_okay?,
        sidekiq_redis: sidekiq_redis_is_okay?,
        service_is_not_terminating: !terminating_trigger_file_exists?,
      },
      host: `hostname`.chop,
      release: Rails.configuration.app_release,
      environment: Rails.configuration.app_env,
      status: "working",
    }
  end

  def db_is_okay?
    ActiveRecord::Base.connection.query("select 1;") == [[1]]
  rescue => _
    false
  end

  def sidekiq_redis_is_okay?
    time = Time.now.to_i.to_s
    Sidekiq.redis { |c| c.set("my_status", time) } && time == Sidekiq.redis { |c| c.get("my_status") }
  rescue => _
    false
  end

  def terminating_trigger_file_exists?
    File.exist?(Rails.root.join("tmp", "terminating.tmp"))
  end
end
