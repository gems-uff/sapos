# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ClassSchedulesHelper

  def _start_date_column(record, options, attribute, same=nil)
    unless record.persisted?
      record.send("#{attribute}=", DateTime.current.midnight)
    end
    config = ActiveScaffold::Config::Core.new(:class_schedule)
    render(:partial => "class_schedules/date_widget", :locals => { 
      config: config,
      record: record,
      options: options,
      attribute: attribute,
      same: same
    })
  end

  def _end_date_column(record, options, attribute, same=nil)
    unless record.persisted?
      record.send("#{attribute}=", DateTime.current.midnight + 1.day - 1.second)
    end
    config = ActiveScaffold::Config::Core.new(:class_schedule)
    render(:partial => "class_schedules/date_widget", :locals => { 
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

  def enrollment_adjust_form_column(record, options)
    _start_date_column(record, options, :enrollment_adjust, :enrollment_start)
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
end