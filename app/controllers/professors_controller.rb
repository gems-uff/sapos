class ProfessorsController < ApplicationController
  active_scaffold :professor do |config|
    config.list.columns = [:name, :cpf, :birthdate]    
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_professor_label    
    config.create.columns = [:name, :cpf, :birthdate]
    config.update.columns = [:name, :cpf, :birthdate]
    config.show.columns = [:name, :cpf, :birthdate, :scholarships, :advisements]
    
  end
end 