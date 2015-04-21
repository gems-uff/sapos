# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class PhasesController < ApplicationController
  authorize_resource

  active_scaffold :phase do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :description, :is_language, :extend_on_hold]
    config.create.label = :create_phase_label
    config.columns[:enrollments].form_ui = :record_select
#    config.columns[:levels].form_ui = :select
    form_columns = [:name, :description, :is_language, :extend_on_hold, :phase_durations]
    config.create.columns = form_columns
    config.update.columns = form_columns
    config.show.columns = form_columns + [:enrollments]
  end
#  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

end 