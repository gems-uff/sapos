# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module CourseClassesPdfHelper

  def summary_header(pdf, options={})
    course_class ||= options[:course_class]

    widths = [576, 100, 130]

    top_header = [["<b>#{I18n.t("pdf_content.course_class.summary.course_name").upcase}</b>",
                   "<b>#{I18n.t("pdf_content.course_class.summary.year_semester").upcase}</b>",
                   "<b>#{I18n.t("pdf_content.course_class.summary.lesson").upcase}</b>"
                  ]]

    top_data = [[
                    course_class.course.name + (course_class.name.blank? ? '' : " (#{course_class.name})"),
                    "#{course_class.semester}º/#{course_class.year}",
                    ''
                ]]

    simple_pdf_table(pdf, widths, top_header, top_data) do |table|
      table.column(0).align = :left
      table.column(0).padding = [2, 4]
    end
  end

  def summary_table(pdf, options={})
    course_class ||= options[:course_class]

    table_width = [30, 105, 285, 45, 45, 60, 236]

    header = [["<b>#{I18n.t("pdf_content.course_class.summary.sequential_number")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.enrollment_number")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.student_name")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.final_grade")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.attendance")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.situation")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.obs")}</b>"]]

    unless course_class.class_enrollments.empty?
      i=0
      table_data = course_class.class_enrollments.joins({:enrollment => :student}).order("students.name").map do |class_enrollment|
        [
            i+=1,
            class_enrollment.enrollment.enrollment_number,
            class_enrollment.enrollment.student.name,
            number_to_grade(class_enrollment.grade),
            class_enrollment.attendance_to_label,
            class_enrollment.situation == I18n.translate("activerecord.attributes.class_enrollment.situations.registered") ? "" : class_enrollment.situation,
            class_enrollment.obs
        ]
      end
    else
      table_data = []
    end

    simple_pdf_table(pdf, table_width, header, table_data, distance: 0) do |table|
      table.column(2).align = :left
      table.column(2).padding = [2, 4]
    end


    pdf.move_down 50
  end

  def summary_footer(pdf, options={})
    course_class ||= options[:course_class]

    pdf.text '_________________________________________________________', :align => :center
    pdf.move_down 5
    pdf.font_size 10
    pdf.text "#{course_class.professor.name}", :align => :center
  end

end
