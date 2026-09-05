# frozen_string_literal: true

require "axlsx"
require "roo"

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
       I18n.t("xls_content.course_class.summary.active_scholarship"),
       I18n.t("xls_content.course_class.summary.created_at")]
      class_enrollments.each_with_index do |class_enrollment, index|
        sheet.add_row build_summary_row(class_enrollment, index)
      end
    end
    p.to_stream.read
  end

  def extract_cell(row, index)
    return nil if index.nil?
    return nil if index >= row.length
    value = row[index]
    return nil if value.nil?
    value.to_s.strip.presence
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
      scholarship_status(class_enrollment),
      I18n.l(class_enrollment.created_at, format: :defaultdatetime)

    ]
  end
  def scholarship_status(class_enrollment)
    key = class_enrollment.enrollment.has_active_scholarship_now? ? "active_scholarship_true" : "active_scholarship_false"
    I18n.t("xls_content.course_class.summary.#{key}")
  end

  def parse_rows_xls(file)
    raise ArgumentError, "Invalid upload" unless file.is_a?(ActionDispatch::Http::UploadedFile)

    original_filename = file.original_filename.to_s
    extension = File.extname(original_filename).downcase
    valid_filename = extension == ".xlsx" &&
      !original_filename.include?("/") &&
      !original_filename.include?("\\")
    raise ArgumentError, "Invalid file name" unless valid_filename

    spreadsheet = Roo::Spreadsheet.open(file.tempfile.path, extension: extension.delete_prefix("."))
    sheet = spreadsheet.sheet(0)
    header_row = sheet.row(1).map { |value| value.to_s.strip }

    enrollment_index = header_row.index(I18n.t("xls_content.course_class.summary.enrollment_number"))
    grade_index = header_row.index(I18n.t("xls_content.course_class.summary.final_grade"))
    attendance_index = header_row.index(I18n.t("xls_content.course_class.summary.attendance"))
    situation_index = header_row.index(I18n.t("xls_content.course_class.summary.situation"))
    obs_index = header_row.index(I18n.t("xls_content.course_class.summary.obs"))
    raise ArgumentError, "Invalid file format" if enrollment_index.nil? || grade_index.nil?

    rows = {}
    return rows if sheet.last_row < 2
    (2..sheet.last_row).each do |row_number|
      row = sheet.row(row_number)
      next if row.blank?
      enrollment_number = row[enrollment_index]&.to_s
      next if enrollment_number.blank?

      rows[enrollment_number] = {
        grade: extract_cell(row, grade_index),
        attendance: extract_cell(row, attendance_index),
        situation: extract_cell(row, situation_index),
        obs: extract_cell(row, obs_index)
      }
    end
    rows
  end
end
