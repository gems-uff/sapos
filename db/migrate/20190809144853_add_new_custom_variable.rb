class AddNewCustomVariable < ActiveRecord::Migration[5.1]
  def change
    CustomVariable.where(:variable => "professor_login_can_post_grades").first or CustomVariable.create(:variable =>"professor_login_can_post_grades", :value => "no")
  end
end
