# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module CourseClassesPdfHelper
  def i18n_pdft(key, *args)
    key = "pdf_content.course_class." + key
    I18n.t(key, *args)
  end

  def summary_header(pdf, options = {})
    course_class ||= options[:course_class]

    widths = [576, 100, 130]

    top_header = [[
      "<b>#{i18n_pdft("summary.course_name").upcase}</b>",
      "<b>#{i18n_pdft("summary.year_semester").upcase}</b>",
      "<b>#{i18n_pdft("summary.lesson").upcase}</b>"
    ]]

    top_data = [[
      course_class.name_with_class_formated_to_reports,
      "#{course_class.semester}º/#{course_class.year}",
      ""
    ]]

    simple_pdf_table(pdf, widths, top_header, top_data) do |table|
      table.column(0).align = :left
      table.column(0).padding = [2, 4]
    end
  end

  def summary_table(pdf, options = {})
    course_class ||= options[:course_class]

    table_width = [30, 105]
    head = [
      "<b>#{i18n_pdft("summary.sequential_number")}</b>",
      "<b>#{i18n_pdft("summary.enrollment_number")}</b>",
      "<b>#{i18n_pdft("summary.student_name")}</b>",
    ]
    if course_class.course.course_type.has_score
      table_width.concat([285, 45])
      head << "<b>#{i18n_pdft("summary.final_grade")}</b>"
    else
      table_width << 330
    end
    table_width.concat([45, 60, 236])
    head.concat([
      "<b>#{i18n_pdft("summary.attendance")}</b>",
      "<b>#{i18n_pdft("summary.situation")}</b>",
      "<b>#{i18n_pdft("summary.obs")}</b>"
    ])
    header = [head]

    unless course_class.class_enrollments.empty?
      i = 0
      table_data = (
        course_class.class_enrollments
        .joins({ enrollment: :student })
        .order("students.name")
      ).map do |class_enrollment|
        row = []
        row << i += 1
        row << class_enrollment.enrollment.enrollment_number
        row << class_enrollment.enrollment.student.name +
          (class_enrollment.enrollment.has_active_scholarship_now? ? " *" : "")
        if course_class.course.course_type.has_score
          row << number_to_grade(class_enrollment.grade)
        end
        row << class_enrollment.attendance_to_label
        row << class_enrollment.situation == ClassEnrollment::REGISTERED ?
          "" : class_enrollment.situation
        row << class_enrollment.obs
        row
      end
    else
      table_data = []
    end

    simple_pdf_table(
      pdf, table_width, header, table_data, distance: 0
    ) do |table|
      table.column(2).align = :left
      table.column(2).padding = [2, 4]
    end

    pdf.move_down 10
    pdf.text "<b>#{i18n_pdft(
      "summary.active_scholarship_table_footer_subtitle"
    )}</b>", inline_format: true

    pdf.move_down 50
  end

  def summary_footer(pdf, options = {})
    course_class ||= options[:course_class]

    line = "_________________________________________________________"
    pdf.text line, align: :center
    pdf.move_down 5
    pdf.font_size 10
    pdf.text "#{course_class.professor.name}", align: :center
  end

  def summary_emails_table(pdf, options = {})
    course_class ||= options[:course_class]

    table_width = [30, 105, 285, 386]

    header = [[
      "<b>#{i18n_pdft("summary.sequential_number")}</b>",
      "<b>#{i18n_pdft("summary.enrollment_number")}</b>",
      "<b>#{i18n_pdft("summary.student_name")}</b>",
      "<b>#{i18n_pdft("summary.student_email")}</b>"
    ]]

    unless course_class.class_enrollments.empty?
      i = 0
      table_data = (
        course_class.class_enrollments
          .joins({ enrollment: :student })
          .order("students.name")
      ).map do |class_enrollment|
        [
            i += 1,
            class_enrollment.enrollment.enrollment_number,
            class_enrollment.enrollment.student.name +
              (class_enrollment.enrollment.has_active_scholarship_now? ?
                " *" : ""),
            class_enrollment.enrollment.student.email
        ]
      end
    else
      table_data = []
    end

    simple_pdf_table(
      pdf, table_width, header, table_data, distance: 0
    ) do |table|
      table.column(2).align = :left
      table.column(2).padding = [2, 4]
      table.column(3).align = :left
      table.column(3).padding = [2, 4]
    end

    pdf.move_down 10
    pdf.text "<b>#{i18n_pdft(
      "summary.active_scholarship_table_footer_subtitle"
    )}</b>", inline_format: true
  end
end
