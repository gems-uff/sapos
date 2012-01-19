class ScholarshipsController < ApplicationController
  active_scaffold :scholarship do |config|
    config.actions.swap :search, :field_search #Enables advanced search A.K.A FieldSearch
    
    config.list.sorting = {:scholarship_number => 'ASC'}
    config.list.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :start_date, :end_date]
    
    config.field_search.columns = [:level, :sponsor, :scholarship_type, :start_date, :end_date]
    
    config.columns[:start_date].search_sql = 'scholarships.start_date'
    
    config.create.label = :create_scholarship_label
    config.columns[:sponsor].form_ui = :select
    config.columns[:scholarship_type].form_ui = :select
    config.columns[:level].form_ui = :select
    config.columns[:professor].form_ui = :record_select
    
    config.columns[:start_date].options = {:format => :monthyear}
    config.columns[:end_date].options = {:format => :monthyear}
    
    config.create.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :professor, :start_date, :end_date, :obs, :enrollments]
    config.update.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :professor, :start_date, :end_date, :obs, :enrollments]
    config.show.columns =   [:scholarship_number, :level, :sponsor, :scholarship_type, :professor, :start_date, :end_date, :obs, :enrollments]
  end
  record_select :per_page => 10, :search_on => [:scholarship_number], :order_by => 'scholarship_number', :full_text_search => true
end 