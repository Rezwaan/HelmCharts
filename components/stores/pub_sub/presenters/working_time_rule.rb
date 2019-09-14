class Stores::PubSub::Presenters::WorkingTimeRule
  def initialize(dto:)
    @working_time_rule = dto
  end

  def present
    {
      id: @working_time_rule.id,
      name: @working_time_rule.name,
      week_working_time: @working_time_rule.week_working_times.map { |week_working_time|
        {
          weekday: week_working_time.weekday,
          start_from: week_working_time.start_from_minutes,
          end_at: week_working_time.end_at_minutes,
        }
      },
    }
  end
end
