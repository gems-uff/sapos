# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Provides functions to convert string to duration
class StringTimeDelta
  DURATIONS = {
    "y" => :year,
    "M" => :month,
    "w" => :week,
    "d" => :day,
    "h" => :hour,
    "m" => :minute,
    "s" => :second
  }
  DURATION_LETTERS = DURATIONS.keys.join
  DURATION_REGEX = /^(-?)([\d.#{DURATION_LETTERS}]+)$/
  FLOAT_DURATION = /^(\d+|\d+\.\d*|\d*\.\d+)([#{DURATION_LETTERS}])(.*)$/
  DAY_DURATION = /^\d+$/
  FLOAT_DAY_DURATION = /^\d*\.\d*$/

  def self.multiply(delta, times)
    return -delta if times == -1
    return delta if times == 1
    return 0.second if times == 0
    return StringTimeDelta.multiply(
      StringTimeDelta.multiply(delta, -times), -1
    ) if times < 0
    delta + StringTimeDelta.multiply(delta, times - 1)
  end


  # Based on Rufus::Scheduler.parse_duration
  # https://github.com/jmettraux/rufus-scheduler/blob/6bf176a30bf1703019ef5a3c808403591267a368/lib/rufus/scheduler/util.rb#L148
  # w -> week
  # d -> day
  # h -> hour
  # m -> minute
  # s -> second
  # M -> month
  # y -> year
  # "nada" -> day
  def self.parse(string, opts = {})
    string = string.to_s

    return 0.second if string == ""

    m = string.match(DURATION_REGEX)

    return nil if m.nil? && opts[:no_error]
    raise ArgumentError.new("cannot parse '#{string}'") if m.nil?

    mod = m[1] == "-" ? -1 : 1
    val = 0.second

    s = m[2]

    while s.length > 0
      m = nil
      if m = s.match(FLOAT_DURATION)
        val += m[1].to_i.send(DURATIONS[m[2]])
      elsif s.match(DAY_DURATION)
        val += s.to_i.send(:day)
      elsif s.match(FLOAT_DAY_DURATION)
        val += s.to_i.send(:day)
      elsif opts[:no_error]
        return nil
      else
        raise ArgumentError.new(
          "cannot parse '#{string}' (especially '#{s}')"
        )
      end
      break unless m && m[3]
      s = m[3]
    end

    StringTimeDelta.multiply(val, mod)
  end
end
