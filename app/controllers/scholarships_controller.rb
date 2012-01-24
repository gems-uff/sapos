class ScholarshipsController < ApplicationController
  active_scaffold :scholarship do |config|
    config.action_links.add 'to_pdf', :label => I18n.t('active_scaffold.to_pdf'), :page => true, :type => :collection
    
    #Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search
    
    config.list.sorting = {:scholarship_number => 'ASC'}
    config.list.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :start_date, :end_date]
    
    config.field_search.columns = [:level, :sponsor, :scholarship_type, :start_date, :end_date]
    
    config.create.label = :create_scholarship_label
    
    config.columns[:start_date].search_sql = "scholarships.start_date"
    config.columns[:end_date].search_sql = "scholarships.end_date"
    
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

      puts date
      
      ["#{column.search_sql} >= ?", date]
    end
  end  
  
  def to_pdf
    each_record_in_page{}
    scholarships = find_page().items
    
    return if scholarships.empty?
    
    pdf = Prawn::Document.new
    
    scholarships.each { |s|
      pdf.text s.scholarship_number
    }    
    
    send_data(pdf.render, :filename => 'relatorio.pdf', :type =>'application/pdf')     
  end
end 