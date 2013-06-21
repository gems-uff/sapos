# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CourseClassesController < ApplicationController
  include NumbersHelper

  active_scaffold :course_class do |config|

    config.columns.add :class_enrollments_count

    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :course, :professor, :year, :semester, :class_enrollments_count]
    config.create.label = :create_course_class_label
    config.update.label = :update_course_class_label

    config.action_links.add 'summary_pdf', :label => I18n.t('pdf_content.course_class.summary.link'), :page => true, :type => :member

    config.columns[:course].clear_link
    config.columns[:professor].clear_link
    config.columns[:course].form_ui = :record_select
    config.columns[:professor].form_ui = :record_select
    config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {:options => ['1', '2']}
    config.columns[:year].options = {:options => ((Date.today.year-5)..Date.today.year).map { |y| y }.reverse}

    config.create.columns =
        [:name, :course, :professor, :year, :semester, :allocations]

    config.update.columns =
        [:name, :course, :professor, :year, :semester, :class_enrollments, :allocations]
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true


  def summary_pdf

    course_class = CourseClass.find(params[:id])

    pdf = Prawn::Document.new(:page_layout => :landscape)

    y_position = pdf.cursor

    pdf.image("#{Rails.root}/config/images/logoIC.jpg", :at => [pdf.bounds.right - 50, y_position],
              :vposition => :top,
              :scale => 0.3
    )

    pdf.font('Courier', :size => 14) do
      pdf.text 'Universidade Federal Fluminense
                Instituto de Computação
                Pós-Graduação'
    end

    pdf.move_down 20

    pdf.font('Courier', :size => 12) do
      pdf.text "#{I18n.t('pdf_content.course_class.summary.title')}".upcase, :align => :center
    end


    pdf.move_down 20

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
      table_data = course_class.class_enrollments.map do |class_enrollment|
        [
            i+=1,
            class_enrollment.enrollment.enrollment_number,
            class_enrollment.enrollment.student.name,
            number_to_grade(class_enrollment.grade),
            class_enrollment.attendance_to_label,
            class_enrollment.situation,
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

    pdf.text '_________________________________________________________', :align => :center
    pdf.move_down 5
    pdf.font_size 10
    pdf.text "#{course_class.professor.name}", :align => :center

    send_data(pdf.render, :filename => "#{I18n.t('pdf_content.course_class.summary.title')} -  #{course_class.name || course_class.course.name}.pdf", :type => 'application/pdf')
  end


end 