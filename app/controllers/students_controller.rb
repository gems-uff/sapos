class StudentsController < ApplicationController
  active_scaffold :student do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :cpf, :enrollments]
    config.create.label = :create_student_label   
    config.update.label = :update_student_label

#    config.columns[:birthdate].form_ui = :calendar_date_select         
    config.columns[:country].form_ui = :select
    config.columns[:state].form_ui = :select
    config.columns[:city].form_ui = :select
    config.columns[:civil_status].form_ui = :select
    config.columns[:birthplace].form_ui = :select
    config.columns[:courses].form_ui = :record_select                   
    config.columns[:sex].form_ui = :select
    config.columns[:sex].options = {:options => [['Masculino','M'],['Feminino','F']]}
    config.columns[:birthdate].options = {'date:yearRange' => 'c-100:c'}
    config.columns[:civil_status].options = {:options => ['Solteiro(a)','Casado(a)']}
    config.columns[:enrollments].clear_link
    
    config.columns =
       [:name,
        :sex,
        :civil_status,        
        :birthdate,
        :state,
        :city,
        :neighbourhood,
        :address,
        :zip_code,
        :telephone1,
        :telephone2,
        :email,
        :employer,
        :job_position,
        :cpf,
        :identity_number,
        :identity_issuing_body,
        :identity_expedition_date,
        :country,
        :birthplace,
        :father_name,
        :mother_name,
        :obs,
        :courses]
  end          
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 