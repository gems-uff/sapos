class AddNewCustomVariable < ActiveRecord::Migration[5.1]
  def change
    CustomVariable.where(:variable => "professor_login_can_post_grades").first or CustomVariable.create(:description=>"Professor logado no sistema pode lançar notas", :variable =>"professor_login_can_post_grades", :value => "no")
  end
end
