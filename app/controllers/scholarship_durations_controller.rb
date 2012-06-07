class ScholarshipDurationsController < ApplicationController
  active_scaffold :scholarship_duration do |config|
    #Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search
    
    config.field_search.columns = [:scholarship, :start_date, :end_date, :cancel_date,:enrollment]
    config.columns[:start_date].search_sql = 'scholarship_durations.start_date'
    config.columns[:end_date].search_sql = 'scholarship_durations.end_date'
    config.columns[:cancel_date].search_sql = 'scholarship_durations.cancel_date'
    config.columns[:enrollment].search_sql = 'enrollments.enrollment_number'
    config.columns[:scholarship].search_ui = :text
    config.columns[:enrollment].search_ui = :text
    
    config.list.sorting = {:scholarship => 'ASC'}
    config.list.columns = [:scholarship, :start_date, :end_date, :cancel_date,:enrollment]
    config.create.label = :create_scholarship_duration_label     
    config.columns = [:scholarship,:enrollment,:start_date,:cancel_date,:end_date,:obs]
    config.columns[:scholarship].search_sql = 'scholarships.scholarship_number'
    config.columns[:scholarship].sort_by :sql => 'scholarships.scholarship_number'
    config.columns[:scholarship].form_ui = :record_select
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:start_date].options = {:format => :monthyear}
    config.columns[:end_date].options = {:format => :monthyear}
    config.columns[:cancel_date].options = {:format => :monthyear}
    config.create.columns = [:scholarship, :enrollment, :start_date, :end_date, :cancel_date, :obs]
    config.update.columns = [:scholarship, :enrollment, :start_date, :end_date, :cancel_date, :obs]
  end
  
  def self.condition_for_start_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty?  ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i,month.to_i)

      ["#{column.search_sql} >= ?", date]
    end
  end
  
  def self.condition_for_end_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty?  ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i,month.to_i)

      ["#{column.search_sql} >= ?", date]
    end
  end
  
  def self.condition_for_cancel_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty?  ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i,month.to_i)

      ["#{column.search_sql} >= ?", date]
    end
  end
end 