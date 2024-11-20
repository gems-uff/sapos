# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeBooleanColumnsToNonNullable < ActiveRecord::Migration[7.0]
  BOOLEAN_FIELDS = [
    [Admissions::AdmissionPhase, :admission_phases, :can_edit_candidate, false, nil],
    [Admissions::AdmissionPhase, :admission_phases, :candidate_can_edit, false, nil],
    [Admissions::AdmissionPhase, :admission_phases, :candidate_can_see_member, false, nil],
    [Admissions::AdmissionPhase, :admission_phases, :candidate_can_see_shared, false, nil],
    [Admissions::AdmissionPhase, :admission_phases, :candidate_can_see_consolidation, false, nil],
    [Admissions::AdmissionProcessPhase, :admission_process_phases, :partial_consolidation, true, true],
    [Admissions::AdmissionProcess, :admission_processes, :allow_multiple_applications, false, nil],
    [Admissions::AdmissionProcess, :admission_processes, :visible, true, true],
    [Admissions::AdmissionProcess, :admission_processes, :require_session, true, true],
    [Admissions::AdmissionProcess, :admission_processes, :staff_can_edit, false, nil],
    [Admissions::AdmissionProcess, :admission_processes, :staff_can_undo, false, nil],
    [Admissions::AdmissionReportConfig, :admission_report_configs, :hide_empty_sections, false, nil],
    [Admissions::AdmissionReportConfig, :admission_report_configs, :show_partial_candidates, false, nil],
    [Admissions::AdmissionReportGroup, :admission_report_groups, :in_simple, false, nil],
    [Advisement, :advisements, :main_advisor, false, false],
    [ClassEnrollment, :class_enrollments, :disapproved_by_absence, false, false],
    [ClassEnrollment, :class_enrollments, :grade_not_count_in_gpr, false, false],
    [CourseClass, :course_classes, :not_schedulable, false, false],
    [CourseType, :course_types, :has_score, false, nil],
    [CourseType, :course_types, :schedulable, true, true],
    [CourseType, :course_types, :show_class_name, true, true],
    [CourseType, :course_types, :allow_multiple_classes, false, false],
    [CourseType, :course_types, :on_demand, false, false],
    [Course, :courses, :available, true, true],
    [DismissalReason, :dismissal_reasons, :show_advisor_name, false, false],
    [EmailTemplate, :email_templates, :enabled, true, true],
    [EnrollmentHold, :enrollment_holds, :active, true, true],
    [EnrollmentStatus, :enrollment_statuses, :user, false, nil],
    [Admissions::FilledForm, :filled_forms, :is_filled, false, nil],
    [Level, :levels, :show_advisements_points_in_list, false, nil],
    [Notification, :notifications, :individual, true, true],
    [Notification, :notifications, :has_grades_report_pdf_attachment, false, false],
    [Phase, :phases, :is_language, false, false],
    [Phase, :phases, :extend_on_hold, false, false],
    [Phase, :phases, :active, true, true],
    [Admissions::RankingConfig, :ranking_configs, :candidate_can_see, false, nil],
    [ReportConfiguration, :report_configurations, :use_at_report, false, nil],
    [ReportConfiguration, :report_configurations, :use_at_transcript, false, nil],
    [ReportConfiguration, :report_configurations, :use_at_grades_report, false, nil],
    [ReportConfiguration, :report_configurations, :use_at_schedule, false, nil],
    [ReportConfiguration, :report_configurations, :signature_footer, false, nil],
    [ScholarshipSuspension, :scholarship_suspensions, :active, true, true],
  ]

  def up
    BOOLEAN_FIELDS.each do |model, table, attr, default, old|
      model.where(attr => nil).update_all(attr => false)
      change_column_null(table, attr, false)
      change_column_default(table, attr, default)
    end
  end

  def down
    BOOLEAN_FIELDS.each do |model, table, attr, default, old|
      change_column_null(table, attr, true)
      change_column_default(table, attr, old)
    end
  end
end
