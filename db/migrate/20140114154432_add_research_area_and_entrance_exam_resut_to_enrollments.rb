class AddResearchAreaAndEntranceExamResutToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :research_area_id, :integer
    add_column :enrollments, :entrance_exam_result, :string
    remove_column :enrollments, :field_of_study
  end
end
