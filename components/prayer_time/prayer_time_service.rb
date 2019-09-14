module PrayerTime
  class PrayerTimeService
    def initialize(latitude:, longitude:, calculation_method: "Makkah")
      @calculation_method = calculation_method
      @prayer_time = PrayerTimes.new(calculation_method)
      @latitude = latitude
      @longitude = longitude
      @zone = ActiveSupport::TimeZone.new("Asia/Riyadh") # TODO: It should based on lat/lng country/state
      @zone_code = @zone&.utc_offset.to_f / 3600
    end

    # @param time_with_zone [ActiveSupport::TimeWithZone] you can set it by accessing zone.at(sec) otherwise the default value is used
    # @return [boolean]
    def currently_praying(time_with_zone: @zone.now)
      start_of_last_prayer, end_of_last_prayer = last_prayer_start_and_end(time_with_zone: time_with_zone)

      time_with_zone.strftime("%H:%M").in?(start_of_last_prayer.strftime("%H:%M")..end_of_last_prayer.strftime("%H:%M"))
    end

    # @param time_with_zone [ActiveSupport::TimeWithZone] you can get it by accessing zone.at(sec) otherwise the default value is used
    # @return [Integer] number of minute till prayer
    def minutes_till_prayer_ends(time_with_zone: @zone.now)
      if currently_praying(time_with_zone: time_with_zone)
        end_of_last_prayer = last_prayer_start_and_end(time_with_zone: time_with_zone)[1]
        return ((time_with_zone - end_of_last_prayer) / 1.minutes).round.abs
      end
      0
    end

    def time_since_last_prayer_ended(time_with_zone: @zone.now)
      unless currently_praying(time_with_zone: time_with_zone)
        end_of_last_prayer = last_prayer_start_and_end(time_with_zone: time_with_zone)[1]
        return ((time_with_zone - end_of_last_prayer) / 1.minutes).round.abs
      end
      0
    end

    def minutes_till_next_prayer_starts(time_with_zone: @zone.now)
      start_of_next_prayer = next_prayer_start_and_end(time_with_zone: time_with_zone)[0]
      ((start_of_next_prayer - time_with_zone) / 1.minutes).round.abs
    end

    def prayer_time_overlaping_minutes(time_range)
      prayer_time_range = last_prayer_time_range_by_time(time_range.end, (time_range.end - 1.day).to_date)
      # return 0 minutes if prayer time is not overlaping order delivery time
      return 0 if prayer_time_range.end < time_range.begin || prayer_time_range.begin > time_range.end

      overlaping_range = [time_range.begin, prayer_time_range.begin].max..[time_range.end, prayer_time_range.end].min
      ((overlaping_range.end - overlaping_range.begin) / 1.minutes).round.abs
    end

    def next_prayer_start_and_end(time_with_zone: @zone.now)
      next_prayer = prayer_hash(date: time_with_zone.to_date).detect { |_, time| time >= time_with_zone.strftime("%H:%M") }
      if next_prayer
        next_prayer_time_type = next_prayer[0]
        start_of_next_prayer = @zone.parse(next_prayer[1])
      else
        next_prayer_time_type = "Fajr"
        start_of_next_prayer = @zone.parse(prayer_hash(date: time_with_zone.to_date)[next_prayer_time_type]) + 1.day
      end
      end_of_next_prayer = next_prayer_time_type == "Isha" ? start_of_next_prayer + 55.minutes : start_of_next_prayer + 45.minutes
      [start_of_next_prayer, end_of_next_prayer]
    end

    private

    def prayer_hash(date: Date.today)
      co = @zone_code || 3
      @prayer_time.get_times(
        date,
          [@latitude, @longitude],
          co
      ).slice("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")
    end

    def sorted_prayers(date: Date.today)
      co = @zone_code || 3
      all_prayers = @prayer_time.get_times(
        date,
          [@latitude, @longitude],
          co
      )
      [
        ["Fajr", all_prayers["Fajr"]],
        ["Dhuhr", all_prayers["Dhuhr"]],
        ["Asr", all_prayers["Asr"]],
        ["Maghrib", all_prayers["Maghrib"]],
        ["Isha", all_prayers["Isha"]],
      ]
    end

    # returns an array with two values:
    # [start_time, end_time]
    def last_prayer_start_and_end(time_with_zone: @zone.now)
      time_range = last_prayer_time_range_by_time(time_with_zone, (time_with_zone - 1.day).to_date)
      [time_range.begin, time_range.end]
    end

    def last_prayer_time_range_by_time(from_time, date_before = Date.yesterday)
      last_prayer = sorted_prayers(date: from_time.to_date).select { |_, time| time < from_time.strftime("%H:%M") }.to_a.last

      if last_prayer
        last_prayer_time_type = last_prayer[0]
        start_of_last_prayer = @zone.parse(last_prayer[1])
      else
        last_prayer_time_type = "Isha"
        start_of_last_prayer = @zone.parse(prayer_hash(date: date_before)["Isha"]) - 1.day
      end

      end_of_last_prayer = last_prayer_time_type == "Isha" ? start_of_last_prayer + 55.minutes : start_of_last_prayer + 45.minutes
      start_of_last_prayer..end_of_last_prayer
    end
  end
end
