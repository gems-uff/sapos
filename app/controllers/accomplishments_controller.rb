class AccomplishmentsController < ApplicationController
  active_scaffold :accomplishment do |config|
    config.list.sorting = {:enrollment => 'ASC'}
    config.search.columns = [:enrollment] 
    config.columns[:enrollment].search_sql = 'enrollments.enrollment_number'
    config.columns[:conclusion_date].options = {:format => :monthyear}
    config.list.columns = [:enrollment, :phase, :conclusion_date, :obs]
    config.create.label = :create_accomplishment_label
    config.search.columns = [:phase] 
    config.columns[:phase].form_ui = :select
    config.columns[:enrollment].form_ui = :record_select
    config.create.columns = [:phase, :enrollment, :conclusion_date, :obs]
    config.update.columns = [:phase, :enrollment, :conclusion_date, :obs]
  end
end