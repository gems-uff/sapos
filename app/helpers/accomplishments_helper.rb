module AccomplishmentsHelper
  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")    
  @@range = @@config["scholarship_year_range"] 
  
  def conclusion_date_form_column(record,options)    
    date_select :record, :conclusion_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range
       }.merge(options)
  end
end