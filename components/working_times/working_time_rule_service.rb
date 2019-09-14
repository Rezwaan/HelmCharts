class WorkingTimes::WorkingTimeRuleService
  include Common::Helpers::PaginationHelper

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    working_time_rules = WorkingTimes::WorkingTimeRule.where(nil)
    working_time_rules = working_time_rules.by_id(criteria[:id]) if criteria[:id].present?
    working_time_rules = working_time_rules.by_related_to_type(criteria[:related_to_type]) if criteria[:related_to_type].present?
    working_time_rules = working_time_rules.by_related_to_id(criteria[:related_to_id]) if criteria[:related_to_id].present?
    working_time_rules = working_time_rules.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: working_time_rules, page: page, per_page: per_page) do |working_time_rule|
      create_dto(working_time_rule)
    end
  end

  def create(name:, week_working_times:, assignments:, data: {})
    wtr = WorkingTimes::WorkingTimeRule.new(name: name)

    if overlapping_working_hours?(week_working_times: week_working_times)
      wtr.errors.add(:working_hours, "overlapping working hours")
      return wtr.errors
    end

    week_working_times.each do |week_working_time|
      attrs = {
        weekday: week_working_time["weekday"],
        start_from_minutes: str_to_minutes(week_working_time["start_from"]),
        end_at_minutes: str_to_minutes(week_working_time["end_at"]),
      }
      wtr.week_working_times.build(attrs)
    end
    assignments.each do |assignment|
      wtr.working_time_rule_assignments.build(related_to_type: assignment["related_to_type"], related_to_id: assignment["related_to_id"])
    end

    if wtr.save
      publish_pubsub(working_time_rule: wtr, info: data)
      return create_dto(wtr)
    else
      return wtr.errors
    end
  end

  def upsert(related_to_type:, related_to_id:, week_working_times:)
    return nil unless related_to_type.present? && related_to_id.present?
    existing_wtr = WorkingTimes::WorkingTimeRuleAssignment.where(related_to_type: related_to_type, related_to_id: related_to_id).first&.working_time_rule
    if week_working_times.nil?
      if existing_wtr
        return delete(id: existing_wtr.id)
      end
      return nil
    end

    data = {"related_to_type" => related_to_type, "related_to_id" => related_to_id}

    if existing_wtr
      return update(id: existing_wtr.id, week_working_times: week_working_times, data: data)
    else
      return create(name: "#{related_to_type}-#{related_to_id}", week_working_times: week_working_times, assignments: [data], data: data)
    end
  end

  def update(id:, week_working_times:, data: {})
    wtr = WorkingTimes::WorkingTimeRule.find(id)

    if overlapping_working_hours?(week_working_times: week_working_times)
      wtr.errors.add(:working_hours, "overlapping working hours")
      return wtr.errors
    end

    wtr.week_working_times = []
    week_working_times.each do |week_working_time|
      attrs = {
        weekday: week_working_time["weekday"],
        start_from_minutes: str_to_minutes(week_working_time["start_from"]),
        end_at_minutes: str_to_minutes(week_working_time["end_at"]),
      }
      wtr.week_working_times.build(attrs)
    end
    if wtr.save
      publish_pubsub(working_time_rule: wtr, info: data)
      return create_dto(wtr)
    else
      return wtr.errors
    end
  end

  def fetch(id:)
    working_time_rule = WorkingTimes::WorkingTimeRule.find_by(id: id)
    create_dto(working_time_rule)
  end

  def delete(id:)
    wtr = WorkingTimes::WorkingTimeRule.find(id)
    if wtr.destroy
      return create_dto(wtr)
    else
      return wtr.errors
    end
  end

  def create_dto(working_time_rule)
    return unless working_time_rule
    WorkingTimes::WorkingTimeRuleDTO.new({
      id: working_time_rule.id,
      name: working_time_rule.name,
      week_working_times: working_time_rule.week_working_times.map { |week_working_time| create_week_working_time_dto(week_working_time) },
    })
  end

  def create_week_working_time_dto(week_working_time)
    WorkingTimes::WeekWorkingTimeDTO.new({
      weekday: week_working_time.weekday,
      start_from_minutes: week_working_time.start_from_minutes,
      end_at_minutes: week_working_time.end_at_minutes,
    })
  end

  private

  def str_to_minutes(str)
    hour, minutes = str.split(":")
    hour.to_i * 60 + minutes.to_i
  end

  def publish_pubsub(working_time_rule:, info: {})
    data = Stores::PubSub::Presenters::WorkingTimeRule.new(dto: working_time_rule).present
    if info["related_to_type"] == "Brands::Brand"
      Brands::Workers::UpdateWorkingTimesWorker.perform_async(info["related_to_id"], data)
    else
      Stores::StoreService.new.publish_pubsub_by_store(store_id: info["related_to_id"], data: data)
    end
  end

  def overlapping_working_hours?(week_working_times:)
    overlapped = false

    grouped_week_hours = week_working_times.group_by { |a| a[:weekday] }
    filtered = grouped_week_hours.values.select { |a| a.size > 1 }

    filtered.collect do |working_hours|
      working_hours.sort_by! { |week_hours| str_to_minutes(week_hours[:start_from]) }
    end

    filtered.each do |working_hours|
      working_hours.each_with_index do |working_hour, index|
        if index + 1 < working_hours.size
          compared_to = working_hours[index + 1]
          overlapped = (str_to_minutes(working_hour[:start_from])..str_to_minutes(working_hour[:end_at])).overlaps?(str_to_minutes(compared_to[:start_from])..str_to_minutes(compared_to[:end_at]))
        end

        break if overlapped
      end
    end

    overlapped
  end
end
