module ScholarshipsHelper
  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")    
  @@range = @@config["scholarship_year_range"]    
  
  def start_date_form_column(record,options)                
    date_select :record, :start_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range
    }    
  end
  
  def start_date_search_column(record,options)                
    local_options = {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :prefix => options[:name]
    }
    
    select_date record[:start_date], options.merge(local_options)
  end  
  
  def end_date_search_column(record,options)                
    local_options = {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :prefix => options[:name]
    }
    
    select_date record[:end_date], options.merge(local_options)
  end    
  
  def end_date_form_column(record,options)    
#    TODO solução temporária para datas vazias (dia padrão vindo 1 por causa do discard_day)
#    NOTE: Discarded selects will default to 1. So if no month select is available, January will be assumed
# => http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#M001698  
    record.end_date = nil if record.end_date.year < 1000 unless record.end_date.nil?
    
    date_select :record, :end_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true
    }        
  end
end