class AddObsToProfessors < ActiveRecord::Migration
  def change
    add_column :professors, :obs, :text
  end
end
