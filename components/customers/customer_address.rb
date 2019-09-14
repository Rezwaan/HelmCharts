# == Schema Information
#
# Table name: customer_addresses
#
#  id          :bigint           not null, primary key
#  latitude    :decimal(10, 8)   not null
#  longitude   :decimal(11, 8)   not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  backend_id  :string           not null
#  customer_id :bigint           not null
#
# Indexes
#
#  index_customer_addresses_on_customer_id                 (customer_id)
#  index_customer_addresses_on_customer_id_and_backend_id  (customer_id,backend_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#

class Customers::CustomerAddress < ApplicationRecord
  belongs_to :customer, class_name: "Customers::Customer"
end
