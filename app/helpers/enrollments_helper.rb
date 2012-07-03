module EnrollmentsHelper   
  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")    
  @@range = @@config["scholarship_year_range"]    
  
  #overriding dismissal date to_label
  def dismissal_column(record)
    I18n.localize(record.dismissal.to_label.to_date, {:format => :monthyear}) unless record.dismissal.nil? or record.nil?
  end

  def approval_date_form_column(record,options)
    date_select :record, :approval_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
    }.merge(options)
  end    
  
  def conclusion_date_form_column(record,options)
    date_select :record, :conclusion_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
    }.merge(options)
  end  
  
  def date_form_column(record,options)
    date_select :record, :date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
    }.merge(options)
  end
  
  def cancel_date_form_column(record,options)   
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
    date_select :record, :admission_date, {
       :discard_day => true,         
       :start_year => Time.now.year - @@range,
       :end_year => Time.now.year + @@range,
       :include_blank => true,
       :default => nil       
     }.merge(options)                      
  end   
  
#  TODO , quando se edita uma matrícula, esta retorna todas as Realizações de etapa que o nível da matrícula
#  porém o evento de on change do select de nível não está sendo possível por causa do javascript (pesquisar mais a fundo)
#  métodos envolvidos "active_scaffold.js" -> render_form_field & replace_html
  def options_for_association_conditions(association)
    if association.name == :phase      
      enrollment_id = params[:id]
      enrollment = Enrollment.find_by_id(enrollment_id) 
      
      level_id = enrollment.nil? ? params[:value] : enrollment.level_id #recupera level_id vindo do parâmetro de atualização
      
      ["phases.id IN (
       SELECT phases.id
       FROM phases
       LEFT OUTER JOIN phase_durations
       ON phase_durations.phase_id = phases.id
       WHERE phase_durations.level_id = ?
       )",level_id]
    else
      super
    end
  end  
end
