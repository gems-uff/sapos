class AddNewCustomVariables < ActiveRecord::Migration[5.1]
  def change

    CustomVariable.where(:variable => "minimum_grade_for_approval").first or CustomVariable.create(:variable =>"minimum_grade_for_approval", :value => "6.0")
    CustomVariable.where(:variable => "grade_of_disapproval_for_absence").first or CustomVariable.create(:variable =>"grade_of_disapproval_for_absence", :value => "0.0")

  end
end
