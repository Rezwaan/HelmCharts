# == Schema Information
#
# Table name: integration_id_mappings
#
#  id         :bigint           not null, primary key
#  str        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_integration_id_mappings_on_str  (str) UNIQUE
#

class Integrations::IntegrationIdMapping < ApplicationRecord
end
