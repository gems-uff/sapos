# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module SharedPdfConcern
  extend ActiveSupport::Concern

  def render_class_schedules_class_schedule_pdf(year, semester)
    course_classes = CourseClass.where(year: year, semester: semester)
    on_demand = Course.joins(:course_type)
      .where(course_types: { on_demand: true })
    render_to_string(
      template: "class_schedules/class_schedule_pdf",
      type: "application/pdf",
      formats: [:pdf],
      assigns: {
        year: year,
        semester: semester,
        course_classes: course_classes,
        on_demand: on_demand
      }
    )
  end

  def render_course_classes_summary_pdf(course_class)
    render_to_string(
      template: "course_classes/summary_pdf",
      type: "application/pdf",
      formats: [:pdf],
      assigns: {
        course_class: course_class
      }
    )
  end

  def render_enrollments_academic_transcript_pdf(enrollment, filename = "transcript.pdf")
    class_enrollments = enrollment.class_enrollments
      .where(situation: ClassEnrollment::APPROVED)
      .joins(:course_class)
      .order("course_classes.year", "course_classes.semester")

    accomplished_phases = enrollment.accomplishments.order(:conclusion_date)

    render_to_string(
      template: "enrollments/academic_transcript_pdf",
      type: "application/pdf",
      formats: [:pdf],
      assigns: {
        filename: filename,
        enrollment: enrollment,
        class_enrollments: class_enrollments,
        accomplished_phases: accomplished_phases,
      }
    )
  end

  def render_enrollments_grades_report_pdf(enrollment, filename = "grades_report.pdf")
    class_enrollments = enrollment.class_enrollments
      .where(situation: ClassEnrollment::APPROVED)
      .joins(:course_class)
      .order("course_classes.year", "course_classes.semester")
    accomplished_phases = enrollment.accomplishments.order(:conclusion_date)
    deferrals = enrollment.deferrals.order(:approval_date)
    render_to_string(
      template: "enrollments/grades_report_pdf",
      type: "application/pdf",
      formats: [:pdf],
      assigns: {
        filename: filename,
        enrollment: enrollment,
        class_enrollments: class_enrollments,
        accomplished_phases: accomplished_phases,
        deferrals: deferrals
      }
    )
  end

  def render_assertion_pdf(assertion)
    render_to_string(
      template: "assertions/assertion_pdf",
      type: "application/pdf",
      formats: [:pdf],
      assigns: {
        assertion: assertion
      }
    )
  end
end
