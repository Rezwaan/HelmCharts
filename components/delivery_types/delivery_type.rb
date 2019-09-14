class DeliveryTypes::DeliveryType < Struct.new(:id, :key, :can_mark_delivered)
  DELIVERY_TYPES = [
    { id: 1, key: :own_delivery, can_mark_delivered: false },
    { id: 2, key: :restaurant_delivery, can_mark_delivered: true }
  ]

  class << self
    def find(id)
      if (data = DELIVERY_TYPES.find { |d| d[:id] == id.to_i })
        hash_to_object(data)
      end
    end

    def find_by_key(key)
      if (data = DELIVERY_TYPES.find { |d| d[:key].to_s == key.to_s })
        hash_to_object(data)
      end
    end

    def all
      DELIVERY_TYPES.map { |d| hash_to_object(d) }
    end

    def key_ids
      Hash[DELIVERY_TYPES.map {|d| [d[:key], d[:id]]}]
    end

    private

    def hash_to_object(data)
      self.new(data[:id], data[:key], data[:can_mark_delivered])
    end
  end
end
