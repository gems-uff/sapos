class AddProfessorCanGenerateReportToEnrollmentStatuses < ActiveRecord::Migration[7.0]
  def up
    add_column :enrollment_statuses, :professor_can_generate_report, :boolean, default: true
  end
  def down
    remove_column :enrollment_statuses, :professor_can_generate_report
  end
end
