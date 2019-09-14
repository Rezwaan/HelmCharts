module ExceptionHandler
  # provides the more graceful `included` method
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |_|
      head :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render json: {error: e.record.errors.messages}, status: :unprocessable_entity
    end

    rescue_from ActiveRecord::RecordNotDestroyed do |u|
      head :unprocessable_entity
    end

    rescue_from Pundit::NotAuthorizedError do |_|
      head :forbidden
    end
  end
end
