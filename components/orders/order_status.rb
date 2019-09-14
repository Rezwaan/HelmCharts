class Orders::OrderStatus < Struct.new(:id, :key, :name, :order, :state_id, :state_key, :state_name)
  ORDER_STATES = [
    {id: 1, key: :processing},
    {id: 2, key: :successful},
    {id: 3, key: :failed},
  ]

  ORDER_STATUSES = [
    {id: 1, key: :received_successfully, order: 1, state: 1, status_flow: []},
    {id: 2, key: :accepted_by_store, order: 2, state: 1, status_flow: [1]},
    {id: 3, key: :rejected_by_store, order: 3, state: 3, status_flow: [1]},
    {id: 4, key: :cancelled_by_store, order: 4, state: 3, status_flow: [1]},
    {id: 5, key: :out_for_delivery, order: 5, state: 2, status_flow: [1, 2]},
    {id: 6, key: :cancelled_by_platform, order: 6, state: 3, status_flow: [1, 2, 5]},
    {id: 7, key: :cancelled_after_pickup_by_platform, order: 7, state: 2, status_flow: [1, 2, 5]},
    {id: 8, key: :delivered, order: 8, state: 2, status_flow: [5]},
  ]

  class << self
    def find(id)
      status = sorted.find { |d| d[:id] == id.to_i }

      hash_to_object(status) if status
    end

    def find_by_key(key)
      status = sorted.find { |d| d[:key].to_s == key.to_s }

      hash_to_object(status) if status
    end

    def all
      sorted.map { |d| hash_to_object(d) }
    end

    def key_ids
      Hash[sorted.map { |d| [d[:key], d[:id]] }]
    end

    def sorted
      ORDER_STATUSES.sort_by { |os| os[:order] || os[:id] }
    end

    def allowed_from(status)
      status = ORDER_STATUSES.detect { |d| d[:key].to_s == status.to_s }

      status&.fetch(:status_flow, [])
    end

    def statuses_by_state(state)
      state = ORDER_STATES.find { |os| os[:key] == state.to_sym }

      return [] unless state

      ORDER_STATUSES.filter { |os| os[:state] == state[:id] }.pluck(:key)
    end

    private

    def hash_to_object(status)
      state_key = ORDER_STATES.find { |os| os[:id] == status[:state] }[:key]

      new(
        status[:id],
        status[:key],
        I18n.t("order_statuses.#{status[:key]}"),
        status[:order],
        status[:state],
        state_key,
        I18n.t("order_states.#{state_key}"),
      )
    end
  end
end
