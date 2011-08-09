class ProfessorsController < ApplicationController
  active_scaffold :professor do |config|
    config.list.columns = [:name, :cpf, :birthdate]    
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_professor_label    
    config.create.columns = [:name, :cpf, :birthdate]
    config.update.columns = [:name, :cpf, :birthdate]
    config.show.columns = [:name, :cpf, :birthdate, :scholarships, :advisements]    
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 