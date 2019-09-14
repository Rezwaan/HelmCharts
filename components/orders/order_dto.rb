# TODO: Refactor this to a PORO (Plain Old Ruby Object) and have all the
# properties declared here.
#
# Current properties:
# (Taken from components/orders/order_service.rb#create_dto)
#
# id
# backend_id
# order_key
# status
# status_detail
# state
# state_name
# platform_id
# customer (optional)
# customer_id
# store_id
# store
# customer_address (optional)
# customer_address_id
# customer_notes
# amount
# discount
# delivery_fee
# collect_at_customer
# collect_at_pickup
# offer_applied
# coupon
# returnable
# return_code
# returned_status
# payment_type
# order_type
# currency
# reject_reason
# created_at
# updated_at
# line_items
# platform
# transmission_medium

module Orders
  class OrderDTO < DTO; end
end
