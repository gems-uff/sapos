# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AccomplishmentsController < ApplicationController
  authorize_resource

  active_scaffold :accomplishment do |config|
    config.list.sorting = {:enrollment => 'ASC'}
    
    config.columns[:enrollment].search_sql = 'enrollments.enrollment_number'
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:enrollment].send_form_on_update_column = true
    config.columns[:enrollment].update_columns = [:phase]
    config.columns[:phase].form_ui = :select
    config.columns[:phase].clear_link
    config.columns[:conclusion_date].options = {:format => :monthyear}
    
    columns = [:enrollment, :phase, :conclusion_date, :obs]
    config.create.columns = columns
    config.update.columns = columns
    config.list.columns = columns
    config.search.columns = [:enrollment]
    
    config.create.label = :create_accomplishment_label
  end

end