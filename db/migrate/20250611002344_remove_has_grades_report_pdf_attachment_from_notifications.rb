class RemoveHasGradesReportPdfAttachmentFromNotifications < ActiveRecord::Migration[7.0]
  def up
    grade_report_message = I18n.t("active_scaffold.notification.grades_report_path")
    Notification.find_each do |noti|
      noti.update!(body_template: noti.body_template + grade_report_message) if noti.has_grades_report_pdf_attachment
    end
    remove_column :notifications, :has_grades_report_pdf_attachment, :boolean
  end

  def down
    add_column :notifications, :has_grades_report_pdf_attachment, :boolean
    Notification.find_each do |notification|
      notification.update!(has_grades_report_pdf_attachment: false)
    end
  end
end
