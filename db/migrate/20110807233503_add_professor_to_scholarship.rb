class AddProfessorToScholarship < ActiveRecord::Migration
  def self.up
    add_column :scholarships, :professor_id, :integer
  end

  def self.down
    remove_column :scholarships, :professor_id
  end
end