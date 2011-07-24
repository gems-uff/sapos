class EnrollmentsController < ApplicationController
  active_scaffold :enrollment do |config|
    config.list.columns = [:student, :enrollment_number, :level, :enrollment_status, :admission_date, :dismissal, :obs]    
    config.list.sorting = {:enrollment_number => 'ASC'}
    config.create.label = :create_enrollment_label    
    config.columns[:level].form_ui = :select
    config.columns[:enrollment_status].form_ui = :select
    #config.create.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :dismissal]
    #config.update.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :dismissal]
    
    #the column group is being used to set up the position in which these fiels appear in the screen
    #config.create.columns.add_subgroup "Dados do Aluno" do |group|
    #  group.add(:student)
    #end
    #config.create.columns.add_subgroup "Dados do Desligamento" do |group|
    #  group.add(:dismissal)
    #end
   
    #config.update.columns.add_subgroup "Dados do Aluno" do |group|
    #  group.add(:student)
    #end
    #config.update.columns.add_subgroup "Dados do Desligamento" do |group|
    #  group.add(:dismissal)
    #end
    
  end
end 