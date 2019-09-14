class Stores::SummaryReportService
  def summary_report(criteria: {})
    stores = Stores::Store.by_id(criteria[:store_ids]).includes(:translations)

    generate_report_by(criteria: criteria, stores: stores)
  end

  def set_date_range(criteria: {})
    unless criteria[:operation_day] && criteria[:operation_day][:start] && criteria[:operation_day][:end]
      current_date = Date.today
      criteria[:operation_day] = {}
      criteria[:operation_day][:start] = (current_date - 6.days).strftime("%Y-%m-%d")
      criteria[:operation_day][:end] = current_date.strftime("%Y-%m-%d")
    end
  end

  def generate_report_by(criteria: {}, stores:)
    set_date_range(criteria: criteria)

    x_axis = (criteria[:operation_day][:start]..criteria[:operation_day][:end]).to_a

    generate_report(stores, criteria, x_axis)
  end

  def generate_report(stores, criteria, x_axis)
    criteria[:type] = criteria[:type] || "orders"

    series = []
    data = Orders::OrderService.new.grouped_data(criteria: criteria.merge(store_ids: stores.pluck(:id)), field: ["store_id", "DATE(created_at)"], type: criteria[:type])
    store_date_data = {}
    data.collect do |store_date, value|
      store_date_data[store_date[0]] ||= {}
      store_date_data[store_date[0]][store_date[1]] ||= value
    end
    stores.each_with_index do |store, i|
      store_data = store_date_data[store.id]
      series_data = format_data(data: store_data, x_axis: x_axis)
      series[i] = {data: series_data.sort.to_h.values, name_en: store.name_en, name_ar: store.name_ar, id: store.id}
    end

    {
      series: series,
      x_axis: x_axis,
      title: criteria[:type].titleize,
    }
  end

  def format_data(data: {}, x_axis: [])
    data = data.present? ? data.transform_keys!(&:to_s) : {}

    x_axis.each do |axis|
      data[axis] = 0 unless data[axis]
    end

    data
  end
end
