class StudentsController < ApplicationController
  active_scaffold :student do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :cpf, :enrollments]
    config.create.label = :create_student_label
    config.columns[:courses].form_ui = :record_select
    config.create.columns = [:name, :cpf, :courses, :obs]
    config.update.columns = [:name, :cpf, :courses, :obs]
    
  end
end 