class Admin::Presenters::WorkingTimes::WorkingTimeRule
  def initialize(working_time_rule)
    @working_time_rule = working_time_rule
  end

  def present
    {
      id: @working_time_rule.id,
      name: @working_time_rule.name,
      week_working_time: @working_time_rule.week_working_times.map { |week_working_time|
        {
          weekday: week_working_time.weekday,
          start_from: minutes_to_str(week_working_time.start_from_minutes),
          end_at: minutes_to_str(week_working_time.end_at_minutes),
        }
      },
    }
  end

  private

  def minutes_to_str(minutes)
    (minutes / 60).to_s.rjust(2, "0") + ":" + (minutes % 60).to_s.rjust(2, "0")
  end
end
