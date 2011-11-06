class ScholarshipDurationsController < ApplicationController
  active_scaffold :scholarship_duration do |config|
    config.list.sorting = {:scholarship => 'ASC'}
    config.list.columns = [:scholarship, :start_date, :end_date, :scholarship_end_date, :enrollment]
    config.create.label = :create_scholarship_duration_label
    config.search.columns = [:scholarship] 
    config.columns = [:scholarship_end_date,:scholarship,:enrollment,:start_date,:end_date,:obs]
    config.columns[:scholarship_end_date].sort_by :sql => 'scholarships.end_date'
    config.columns[:scholarship].search_sql = 'scholarships.scholarship_number'
    config.columns[:scholarship].form_ui = :record_select
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:start_date].options = {:format => :monthyear}
    config.columns[:end_date].options = {:format => :monthyear}
    config.create.columns = [:scholarship, :enrollment, :start_date, :end_date, :obs]
    config.update.columns = [:scholarship, :enrollment, :start_date, :end_date, :obs]
  end
end 