# == Schema Information
#
# Table name: customers
#
#  id           :bigint           not null, primary key
#  name         :string
#  phone_number :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  backend_id   :string           not null
#  platform_id  :bigint           not null
#
# Indexes
#
#  index_customers_on_platform_id                 (platform_id)
#  index_customers_on_platform_id_and_backend_id  (platform_id,backend_id) UNIQUE
#

class Customers::Customer < ApplicationRecord
end
