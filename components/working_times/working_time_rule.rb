# == Schema Information
#
# Table name: working_time_rules
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class WorkingTimes::WorkingTimeRule < ApplicationRecord
  has_many :week_working_times, class_name: "WorkingTimes::WeekWorkingTime", dependent: :delete_all
  has_many :working_time_rule_assignments, class_name: "WorkingTimes::WorkingTimeRuleAssignment", dependent: :delete_all

  scope :by_id, ->(id) { where(id: id) }
  scope :by_related_to_type, ->(related_to_type) {
    joins(:working_time_rule_assignments).where(working_time_rule_assignments: {related_to_type: related_to_type})
  }
  scope :by_related_to_id, ->(related_to_id) {
    joins(:working_time_rule_assignments).where(working_time_rule_assignments: {related_to_id: related_to_id})
  }

  # @TODO: Add validation that all week working time are valid without having overlap
end
