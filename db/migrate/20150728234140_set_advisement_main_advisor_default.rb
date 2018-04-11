class SetAdvisementMainAdvisorDefault < ActiveRecord::Migration[5.1]
  def change
  	change_column :advisements, :main_advisor, :boolean, :default => false
  end
end
