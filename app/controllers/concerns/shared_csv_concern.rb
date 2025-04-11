# frozen_string_literal: true

module SharedCsvConcern
  extend ActiveSupport::Concern

  def render_course_classes_summary_csv(class_enrollments)
    CSV.generate(headers: true) do |csv|
      csv << [I18n.t("csv_content.course_class.summary.sequential_number"),
       I18n.t("csv_content.course_class.summary.enrollment_number"),
       I18n.t("csv_content.course_class.summary.student_name"),
       I18n.t("csv_content.course_class.summary.final_grade"),
       I18n.t("csv_content.course_class.summary.attendance"),
       I18n.t("csv_content.course_class.summary.situation"),
       I18n.t("csv_content.course_class.summary.obs"),
       I18n.t("csv_content.course_class.summary.active_scholarship")]
      has_scholarship = I18n.t("csv_content.course_class.summary.active_scholarship_true")
      hasnt_scholarship = I18n.t("csv_content.course_class.summary.active_scholarship_false")
      sequencial_number = 0
      class_enrollments.each do |class_enrollment|
        sequencial_number += 1
        csv << [
          sequencial_number,
          class_enrollment.enrollment.enrollment_number,
          class_enrollment.enrollment.student.name,
          class_enrollment.grade_to_view,
          class_enrollment.attendance_to_label,
          class_enrollment.situation,
          class_enrollment.obs,
          class_enrollment.enrollment.has_active_scholarship_now? ? has_scholarship : hasnt_scholarship]
      end
    end
  end
end
