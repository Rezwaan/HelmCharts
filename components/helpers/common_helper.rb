# frozen_string_literal: true

module Helpers::CommonHelper
  def sort_array_of_objects(array:, direction:, by:)
    array.sort_by! do |object|
      direction == "asc" ? object.send(by) : -object.send(by)
    end
  end

  def convert_hash_to_symbol(data)
    data.each_with_object({}) do |(key, value), hash|
      hash[key.to_sym] = value
    end
  end
end
