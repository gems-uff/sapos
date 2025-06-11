class RemoveHasGradesReportPdfAttachmentFromNotifications < ActiveRecord::Migration[7.0]
  def up
    remove_column :notifications, :has_grades_report_pdf_attachment, :boolean
  end

  def down
    add_column :notifications, :has_grades_report_pdf_attachment, :boolean
    Notification.find_each do |notification|
      notification.update!(has_grades_report_pdf_attachment: false)
    end
  end
end
