module ScholarshipDurationsHelper
  def start_date_form_column(record,options)            
    date_select :record, :start_date, {
         :discard_day => true,
         :start_year => Time.now.year - 15,
         :end_year => Time.now.year + 15
    }
  end
  
  def end_date_form_column(record,options)    
    date_select :record, :end_date, {
         :discard_day => true,
         :start_year => Time.now.year - 15,
         :end_year => Time.now.year + 15
    }
  end  
end
