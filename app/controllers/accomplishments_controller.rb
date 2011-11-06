class AccomplishmentsController < ApplicationController
  active_scaffold :accomplishment do |config|
    config.list.sorting = {:enrollment => 'ASC'}
    config.list.columns = [:enrollment, :phase, :conclusion_date, :obs]
    config.create.label = :create_accomplishment_label
    config.search.columns = [:phase] 
#    config.columns[:phase].search_sql = 'phases.name'
    config.columns[:phase].form_ui = :select
    config.columns[:enrollment].form_ui = :record_select
    config.create.columns = [:phase, :enrollment, :conclusion_date, :obs]
    config.update.columns = [:phase, :enrollment, :conclusion_date, :obs]
  end
end