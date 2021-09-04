# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ClassSchedulesHelper

  def enrollment_start_form_column(record, options)
    unless record.persisted?
      record.enrollment_start = DateTime.current.midnight
    end
    config = ActiveScaffold::Config::Core.new(:class_schedule)
    active_scaffold_input_date_picker config.columns[:enrollment_start], options
  end

  def enrollment_end_form_column(record, options)
    unless record.persisted?
      record.enrollment_end = DateTime.current.midnight + 1.day - 1.second
    end
    config = ActiveScaffold::Config::Core.new(:class_schedule)
    active_scaffold_input_date_picker config.columns[:enrollment_end], options
  end
end