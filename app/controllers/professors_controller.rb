class ProfessorsController < ApplicationController
  active_scaffold :professor do |config|
    config.columns.add :advisement_points
    config.list.columns = [:name, :cpf, :birthdate, :advisement_points]
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_professor_label    
#    config.create.columns = [:name, :cpf, :birthdate]
#    config.update.columns = [:name, :cpf, :birthdate]
    config.columns[:advisement_points].sort_by :method => "advisement_points_order"
    config.columns[:enrollments].associated_limit = nil
    config.columns[:birthdate].options = {'date:yearRange' => 'c-100:c'}    
    config.columns[:civil_status].form_ui = :select
    config.columns[:civil_status].options = {:options => [['Solteiro(a)','solteiro'],
                                                          ['Casado(a)','casado']]}
    config.columns[:sex].form_ui = :select
    config.columns[:sex].options = {:options => [['Masculino','M'],
                                                          ['Feminino','F']]}
    config.columns[:scholarships].form_ui = :record_select               
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