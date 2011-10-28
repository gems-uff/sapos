class ProfessorsController < ApplicationController
  active_scaffold :professor do |config|
    config.list.columns = [:name, :cpf, :birthdate]    
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_professor_label    
#    config.create.columns = [:name, :cpf, :birthdate]
#    config.update.columns = [:name, :cpf, :birthdate]
    config.columns[:enrollments].associated_limit = nil
    config.show.columns = [:name,
                           :cpf,
                           :birthdate,
                           :address,
                           :birthdate,
                           :civil_status,
                           :identity_expedition_date,
                           :identity_issuing_body,
                           :identity_number,
                           :neighbourhood,
                           :sex,
                           :siape,
                           :telephone1,
                           :telephone2,
                           :zip_code,                           
                           :scholarships, 
                           :enrollments]    
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 