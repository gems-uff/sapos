# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ClassSchedulesHelper
  def _start_date_column(record, options, attribute, same = nil)
    unless record.persisted?
      record.send("#{attribute}=", DateTime.current.midnight)
    end
    config = ActiveScaffold::Config::Core.new(:class_schedule)
    render(partial: "class_schedules/date_widget", locals: {
      config: config,
      record: record,
      options: options,
      attribute: attribute,
      same: same
    })
  end

  def _end_date_column(record, options, attribute, same = nil)
    unless record.persisted?
      record.send("#{attribute}=", DateTime.current.midnight + 1.day - 1.second)
    end
    config = ActiveScaffold::Config::Core.new(:class_schedule)
    render(partial: "class_schedules/date_widget", locals: {
      config: config,
      record: record,
      options: options,
      attribute: attribute,
      same: same
    })
  end

  def enrollment_start_form_column(record, options)
    _start_date_column(record, options, :enrollment_start)
  end

  def period_start_form_column(record, options)
    _start_date_column(record, options, :period_start, :enrollment_start)
  end

  def enrollment_end_form_column(record, options)
    _end_date_column(record, options, :enrollment_end)
  end

  def enrollment_insert_form_column(record, options)
    _end_date_column(record, options, :enrollment_insert, :enrollment_end)
  end

  def enrollment_remove_form_column(record, options)
    _end_date_column(record, options, :enrollment_remove, :enrollment_end)
  end

  def period_end_form_column(record, options)
    _end_date_column(record, options, :period_end)
  end

  def grades_deadline_form_column(record, options)
    _end_date_column(record, options, :grades_deadline, :period_end)
  end

  def class_schedule_day_groups(allocations)
    day_order = I18n.translate("date.day_names")
    groups = {}
    allocations.each do |allocation|
      key = [allocation[:start_time], allocation[:end_time], allocation[:room]]
      (groups[key] ||= []) << allocation[:day]
    end
    groups.map do |(start_time, end_time, room), days|
      {
        days: days.sort_by { |day| day_order.index(day) },
        start_time: start_time,
        end_time: end_time,
        room: room
      }
    end.sort_by { |group| day_order.index(group[:days].first) }
  end

  def class_schedule_days_label(days)
    plural_days = days.map { |day| "#{day}s" }
    return plural_days.first if plural_days.size == 1

    "#{plural_days[0...-1].join(", ")} e #{plural_days.last}"
  end

  def class_schedule_allocation_label(group)
    label = "#{class_schedule_days_label(group[:days])}, " \
      "#{group[:start_time]}h às #{group[:end_time]}h"
    if group[:room].present?
      label += ", #{I18n.t(
        "activerecord.attributes.allocation.room"
      )}: #{group[:room]}"
    end
    label
  end
end
