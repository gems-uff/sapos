class StudentsController < ApplicationController
  active_scaffold :student do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_student_label
    config.columns[:courses].form_ui = :record_select
    config.create.columns = [:name, :cpf, :courses, :obs, :enrollments]
    config.update.columns = [:name, :cpf, :courses, :obs, :enrollments]
    
  end
end 