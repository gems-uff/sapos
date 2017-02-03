class AddNewCustomVariables < ActiveRecord::Migration
  def change

    CustomVariable.where(:variable => "minimum_grade_for_approval").first or CustomVariable.create(:name=>"Nota mínima para aprovação", :variable =>"minimum_grade_for_approval", :value => "6.0")
    CustomVariable.where(:variable => "grade_of_disapproval_for_absence").first or CustomVariable.create(:name=>"Nota de reprovação por falta", :variable =>"grade_of_disapproval_for_absence", :value => "1.0")

  end
end
