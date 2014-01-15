class RemoveEntranceExamResultFromEnrollments < ActiveRecord::Migration
  def change
  	remove_column :enrollments, :entrance_exam_result
  end
end
