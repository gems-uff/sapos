class StudentsController < ApplicationController
  active_scaffold :student do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_student_label
  end
end 