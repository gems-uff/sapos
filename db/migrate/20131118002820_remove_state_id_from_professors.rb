class RemoveStateIdFromProfessors < ActiveRecord::Migration
  def change
  	remove_column :professors, :state_id
  end
end
