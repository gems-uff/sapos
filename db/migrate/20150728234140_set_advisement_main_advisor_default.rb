class SetAdvisementMainAdvisorDefault < ActiveRecord::Migration
  def change
  	change_column :advisements, :main_advisor, :boolean, :default => false
  end
end
