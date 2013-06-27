# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class DismissalsController < ApplicationController
  authorize_resource

  active_scaffold :dismissal do |config|
    #Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search
    config.field_search.columns = [:enrollment]
    config.columns[:enrollment].search_ui = :text
    config.columns[:enrollment].search_sql = 'enrollments.enrollment_number'
    config.columns[:date].search_sql = 'dismissals.date'

    config.list.columns = [:enrollment, :dismissal_reason, :date, :obs]
    config.create.label = :create_dismissal_label
    config.columns[:dismissal_reason].form_ui = :select
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:date].options = {:format => :monthyear}
    config.columns[:enrollment].clear_link
    config.columns[:dismissal_reason].clear_link

    config.update.columns = [:enrollment, :date, :dismissal_reason, :obs]
    config.create.columns = [:enrollment, :date, :dismissal_reason, :obs]
  end

end