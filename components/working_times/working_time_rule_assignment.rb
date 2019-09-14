# == Schema Information
#
# Table name: working_time_rule_assignments
#
#  id                   :uuid             not null, primary key
#  related_to_type      :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  related_to_id        :bigint
#  working_time_rule_id :uuid
#
# Indexes
#
#  index_working_time_rule_assignments_on_related_to            (related_to_type,related_to_id)
#  index_working_time_rule_assignments_on_working_time_rule_id  (working_time_rule_id)
#
# Foreign Keys
#
#  fk_rails_...  (working_time_rule_id => working_time_rules.id)
#

class WorkingTimes::WorkingTimeRuleAssignment < ApplicationRecord
  belongs_to :working_time_rule, class_name: "WorkingTimes::WorkingTimeRule"
end
