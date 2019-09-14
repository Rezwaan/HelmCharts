class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  define_model_callbacks :soft_delete, only: [:before, :after]
  define_model_callbacks :restore, only: [:before, :after]

  scope :by_soft_deleted, -> { where.not(deleted_at: nil) }
  scope :by_not_soft_deleted, -> { where(deleted_at: nil) }

  def soft_delete!
    run_callbacks :soft_delete do
      update_columns(deleted_at: Time.now)
    end
  end

  def restore!
    run_callbacks :restore do
      update_columns(deleted_at: nil)
    end
  end

  def deleted?
    deleted_at.present?
  end
end
