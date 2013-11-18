class AddInstitutionIdToProfessors < ActiveRecord::Migration
  def change
    add_column :professors, :institution_id, :integer
    add_index :professors, :institution_id
  end
end
