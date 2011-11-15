class EnrollmentsController < ApplicationController
  active_scaffold :enrollment do |config|
    config.list.columns = [:student, :enrollment_number, :level, :enrollment_status, :admission_date, :dismissal]
    config.list.sorting = {:enrollment_number => 'ASC'}    
    config.create.label = :create_enrollment_label  
    config.update.label = :update_enrollment_label        
    config.columns[:student].sort_by :sql => 'students.name'
    config.columns[:level].form_ui = :select
    config.columns[:enrollment_status].form_ui = :select    
    config.columns[:level].clear_link
    config.columns[:enrollment_status].clear_link
    config.columns[:student].form_ui = :record_select
    #Student can not be configured as record select because it does not allow the user to create a new one, if needed
    #config.columns[:student].form_ui = :record_select        
    config.create.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :scholarship_durations, :dismissal]
    config.update.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :scholarship_durations, :dismissal]
    config.show.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :scholarship_durations, :dismissal]        
  end
  record_select :per_page => 10, :search_on => [:enrollment_number], :order_by => 'enrollment_number', :full_text_search => true
end