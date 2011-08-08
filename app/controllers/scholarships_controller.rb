class ScholarshipsController < ApplicationController
  active_scaffold :scholarship do |config|
    config.list.sorting = {:scholarship_number => 'ASC'}
    config.list.columns = [:scholarship_number, :level, :scholarship_type, :sponsor, :start_date, :end_date]
    config.create.label = :create_scholarship_label
    config.columns[:sponsor].form_ui = :select
    config.columns[:scholarship_type].form_ui = :select
    config.columns[:level].form_ui = :select
    config.columns[:professor].form_ui = :select
    config.create.columns = [:scholarship_number, :level, :scholarship_type, :sponsor, :professor, :start_date, :end_date, :obs, :enrollments]
    config.update.columns = [:scholarship_number, :level, :scholarship_type, :sponsor, :professor, :start_date, :end_date, :obs, :enrollments]
    config.show.columns = [:scholarship_number, :level, :scholarship_type, :sponsor, :professor, :start_date, :end_date, :obs, :enrollments]
  end
  record_select :per_page => 10, :search_on => [:scholarship_number], :order_by => 'scholarship_number'
end 