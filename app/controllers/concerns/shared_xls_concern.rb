# frozen_string_literal: true

require "axlsx"

module SharedXlsConcern
  extend ActiveSupport::Concern

  def render_course_classes_summary_xls(class_enrollments)
    Axlsx.escape_formulas = false
    p = Axlsx::Package.new
    wb = p.workbook
    wb.add_worksheet(name: "Pauta da Turma") do |sheet|
      sheet.add_row [I18n.t("xls_content.course_class.summary.sequential_number"),
       I18n.t("xls_content.course_class.summary.enrollment_number"),
       I18n.t("xls_content.course_class.summary.student_name"),
       I18n.t("xls_content.course_class.summary.student_email"),
       I18n.t("xls_content.course_class.summary.final_grade"),
       I18n.t("xls_content.course_class.summary.attendance"),
       I18n.t("xls_content.course_class.summary.situation"),
       I18n.t("xls_content.course_class.summary.obs"),
       I18n.t("xls_content.course_class.summary.active_scholarship")]
      class_enrollments.each_with_index do |class_enrollment, index|
        sheet.add_row build_summary_row(class_enrollment, index)
      end
    end
    p.to_stream.read
  end


  def build_summary_row(class_enrollment, index)
    [
      index + 1,
      class_enrollment.enrollment.enrollment_number,
      class_enrollment.enrollment.student.name,
      class_enrollment.enrollment.student.email,
      class_enrollment.grade_to_view,
      class_enrollment.attendance_to_label,
      class_enrollment.situation,
      class_enrollment.obs,
      scholarship_status(class_enrollment)
    ]
  end
  def scholarship_status(class_enrollment)
    key = class_enrollment.enrollment.has_active_scholarship_now? ? "active_scholarship_true" : "active_scholarship_false"
    I18n.t("xls_content.course_class.summary.#{key}")
  end
end
