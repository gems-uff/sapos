module EnrollmentsHelper   
  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")    
  @@range = @@config["scholarship_year_range"]    
      
  def cancel_date_form_column(record,options)   
#    TODO solução temporária para datas vazias (dia padrão vindo 1 por causa do discard_day)
#    NOTE: Discarded selects will default to 1. So if no month select is available, January will be assumed
# => http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#M001698
    record.cancel_date = nil if record.cancel_date.year < 1000 unless record.cancel_date.nil?
    
    date_select :record, :cancel_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
    }.merge(options)
  end
  
  def start_date_form_column(record,options)    
    date_select :record, :start_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range
       }.merge(options)
  end
  
  def end_date_form_column(record,options)        
    date_select :record, :end_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range
    }.merge(options)
  end    
  
  def admission_date_form_column(record,options)        
#    TODO solução temporária para datas vazias (dia padrão vindo 1 por causa do discard_day)
#    NOTE: Discarded selects will default to 1. So if no month select is available, January will be assumed
# => http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#M001698
    record.admission_date = nil if record.admission_date.year < 1000 unless record.admission_date.nil?
            
    date_select :record, :admission_date, {
       :discard_day => true,         
       :start_year => Time.now.year - @@range,
       :end_year => Time.now.year + @@range,
       :include_blank => true,
       :default => nil       
     }.merge(options)                      
  end   
  
#  TODO verificar update de coluna, javascript não funcional
#  def options_for_association_conditions(association)
#    if association.name == :phase      
#      level_id = params[:value] #recupera level_id vindo do parâmetro de atualização
#      
#      ["phases.id IN (
#       SELECT phases.id
#       FROM phases
#       LEFT OUTER JOIN phase_durations
#       ON phase_durations.phase_id = phases.id
#       WHERE phase_durations.level_id = ?
#       )#",level_id]
#    else
#      super
#    end
#  end  
end
