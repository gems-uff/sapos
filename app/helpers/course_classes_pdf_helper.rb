# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module CourseClassesPdfHelper

  def summary_header(pdf, options={})
    course_class ||= options[:course_class]

    top_header = [["<b>#{I18n.t("pdf_content.course_class.summary.course_name").upcase}</b>",
                   "<b>#{I18n.t("pdf_content.course_class.summary.year_semester").upcase}</b>",
                   "<b>#{I18n.t("pdf_content.course_class.summary.lesson").upcase}</b>"
                  ]]

    top_width = [490, 100, 130]
    pdf.table(top_header, :column_widths => top_width,
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => 'Courier',
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0,
                              :align => :center
              }
    )

    top_data = [[
                    course_class.course.name + (course_class.name.blank? ? '' : " (#{course_class.name})"),
                    "#{course_class.semester}º/#{course_class.year}",
                    ''
                ]]

    pdf.table(top_data, :column_widths => top_width,
              :row_colors => ["FFFFFF"],
              :cell_style => {:font => 'Courier',
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0
              }
    )
  end

  def summary_table(pdf, options={})
    course_class ||= options[:course_class]

    table_width = [30, 105, 285, 45, 45, 60, 150]

    header = [["<b>#{I18n.t("pdf_content.course_class.summary.sequential_number")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.enrollment_number")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.student_name")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.final_grade")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.attendance")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.situation")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.obs")}</b>"]]

    pdf.table(header, :column_widths => table_width,
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0,
                              :align => :left
              }
    )

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

      pdf.table(table_data, :column_widths => table_width,
                :row_colors => ["FFFFFF", "F0F0F0"],
                :cell_style => {:font => "Courier",
                                :size => 8,
                                :inline_format => true,
                                :border_width => 0
                }
      )
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
