# == Schema Information
#
# Table name: week_working_times
#
#  id                   :uuid             not null, primary key
#  end_at_minutes       :integer          not null
#  start_from_minutes   :integer          not null
#  weekday              :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  working_time_rule_id :uuid
#
# Indexes
#
#  index_week_working_times_on_working_time_rule_id  (working_time_rule_id)
#
# Foreign Keys
#
#  fk_rails_...  (working_time_rule_id => working_time_rules.id)
#

class WorkingTimes::WeekWorkingTime < ApplicationRecord
  belongs_to :working_time_rule, class_name: "WorkingTimes::WorkingTimeRule"

  # @TODO: Add validation that star and end are within range and valid
end
