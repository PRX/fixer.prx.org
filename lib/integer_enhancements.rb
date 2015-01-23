module IntegerEnhancements
  def to_time_string_summary
    time_duration_summary(self)
  end

  def time_duration_in_words(seconds=0)
    return "0 seconds" if seconds <= 0
    time_values = time_duration(seconds)
    [:hour, :minute, :second].inject([]) { |words, unit|
      if (time_values[unit] > 0)
        units_text = (time_values[unit] == 1) ? unit.to_s : unit.to_s.pluralize
        words << "#{time_values[unit]} #{units_text}"
      end
      words
    }.to_sentence
  end

  def time_duration_summary(seconds=0)
    return ":00" if seconds <= 0
    time_values = time_duration(seconds)
    last_zero = true
    nums = [:hour, :minute, :second].collect do |unit|
      if last_zero && (time_values[unit] == 0)
        nil
      else
        last_zero = false
        format("%02d", time_values[unit])
      end
    end.compact
    if nums.size > 1
      nums.join(":")
    else
      ":#{nums[0]}"
    end
  end

  def time_duration(seconds)
    return {:second=>0} if seconds <= 0
    secs = seconds
    [[:hour,3600], [:minute,60], [:second,1]].inject({}) do |values, each|
      unit,size = each
      values[unit] = ((secs <= 0) ? 0 : (secs / size))
      secs = ((secs <= 0) ? 0 : (secs % size))
      values
    end
  end

  def to_hour_of_day_s
    h = self.to_i
    if h == 0
      "12:00:00 midnight"
    elsif h > 0 && h < 12
      "#{h}:00:00 AM"
    elsif h == 12
      "12:00:00 noon"
    elsif h > 12 && h < 24
      "#{h-12}:00:00 PM"
    end
  end

end

class Fixnum
  include IntegerEnhancements
end

class Bignum
  include IntegerEnhancements
end
