# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module EnrollmentsPdfHelper
  def enrollments_table(pdf, options={})
    enrollments ||= options[:enrollments]

    header = [["<b>#{I18n.t("activerecord.attributes.enrollment.student")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.enrollment_number")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.admission_date")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.dismissal")}</b>"]]

    pdf.table(header, :column_widths => [208, 108, 108, 108],
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0
              }
    )

    pdf.table(enrollments, :column_widths => [208, 108, 108, 108],
              :row_colors => ["FFFFFF", "F0F0F0"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0
              }
    )
  end

  def enrollment_header(pdf, options={})
    enrollment ||= options[:enrollment]
    x = 5
    default_margin = 22
    default_margin_indent = 11
    default_margin_x = 20
    font_width = 5.7
    current_x = x

    pdf.font('Courier', :size => 9) do
      pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.right, :height => 120) do
        pdf.stroke_bounds

        data_table = [
          [
            "#{I18n.t('pdf_content.enrollment.header.student_name')}: " +
            enrollment.student.name
          ], [
            "#{I18n.t('pdf_content.enrollment.header.enrollment_number')}: " +
            "#{enrollment.enrollment_number}   ",
            "#{I18n.t('pdf_content.enrollment.header.student_birthdate')}: " +
            "#{rescue_blank_text(enrollment.student.birthdate)}"
          ], [
            "#{I18n.t('pdf_content.enrollment.header.student_birthplace')}: " +
            "#{rescue_blank_text(enrollment.student.birthplace)}"
          ], [
            "#{I18n.t('pdf_content.enrollment.header.student_identity_number')}: " +
            "#{rescue_blank_text(enrollment.student.identity_number)}  ",
            "#{I18n.t('pdf_content.enrollment.header.identity_issuing_body')}: " +
            "#{rescue_blank_text(enrollment.student.identity_issuing_body)}  ",
            "#{I18n.t('pdf_content.enrollment.header.identity_issuing_place')}: " +
            "#{rescue_blank_text(enrollment.student.identity_issuing_place)}"
          ], [
            "#{I18n.t('pdf_content.enrollment.header.student_cpf')}: " +
            "#{rescue_blank_text(enrollment.student.cpf)}"
          ]
        ]

        pdf.indent(x) do
          text_table(pdf, data_table, default_margin_indent)
        end 
        

      end

      height = 80 

      pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.right, :height => height) do
        pdf.stroke_bounds

        pdf.indent(x) do
          pdf.move_down default_margin_indent
          
          pdf.text("#{I18n.t("pdf_content.enrollment.header.course")}: #{enrollment.level.name} #{I18n.t("pdf_content.enrollment.header.graduation")}")
          pdf.move_down default_margin_indent
          
          pdf.text("#{I18n.t("pdf_content.enrollment.header.enrollment_admission_date")}: #{I18n.localize(enrollment.admission_date, :format => :monthyear2)}")
          pdf.move_down default_margin_indent

          enrollment_dismissal_date_text = "#{I18n.t("pdf_content.enrollment.header.enrollment_dismissal_date")}: "
          enrollment_dismissal_date_text += enrollment.dismissal ? " #{"#{I18n.localize(enrollment.dismissal.date, :format => :monthyear2)}"}" : "--"
          enrollment_dismissal_reason_text = "#{I18n.t("pdf_content.enrollment.header.enrollment_dismissal_reason")}:"
          enrollment_dismissal_reason_text += enrollment.dismissal ? " #{enrollment.dismissal.dismissal_reason.name}" : "--"

          enrollment_dismissal_text = enrollment_dismissal_date_text + '     ' + enrollment_dismissal_reason_text
          pdf.text(enrollment_dismissal_text)

        end 
      end
    end

    pdf.move_down 20
  end

  def transcript_table(pdf, options={})
    class_enrollments ||= options[:class_enrollments]
    table_width = [58, 55, 249, 50, 65, 95]

    header = [["<b>#{I18n.t("pdf_content.enrollment.grade_list.course_year_semester")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_code")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_name")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_grade")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_credits")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_workload")}</b>"
              ]]

    pdf.table(header, :column_widths => table_width,
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0,
                              :align => :center
              }
    )

    unless class_enrollments.empty?
      table_data = class_enrollments.map do |class_enrollment|
        [
            "#{class_enrollment.course_class.semester}/#{class_enrollment.course_class.year}",
            class_enrollment.course_class.course.code,
            class_enrollment.course_class.course.name,
            class_enrollment.course_class.course.course_type.has_score ? number_to_grade(class_enrollment.grade) : I18n.t("pdf_content.enrollment.grade_list.course_approved"),
            class_enrollment.course_class.course.credits,
            class_enrollment.course_class.course.workload_text
        ]
      end

      pdf.table(table_data, :column_widths => table_width,
                :row_colors => ["F9F9F9", "F0F0F0"],
                :cell_style => {:font => "Courier",
                                :size => 8,
                                :inline_format => true,
                                :border_width => 0,
                                :align => :center
                }
      ) do |table|
        table.column(2).align = :left
      end      
    end

    footer = [[
      "", 
      "", 
      "<b>#{I18n.t('pdf_content.enrollment.academic_transcript.total_credits')}</b>", 
      "", 
      class_enrollments.joins({:course_class => :course}).sum(:credits).to_i, 
      I18n.translate('activerecord.attributes.course.workload_time', :time => class_enrollments.joins({:course_class => :course}).sum(:workload).to_i)
    ]]
    pdf.table(footer, :column_widths => table_width,
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0,
                              :align => :center
              }
    ) do |table|
      table.column(2).align = :right
    end

    pdf.move_down 20
  end

  def accomplished_table(pdf, options={})
    accomplished_phases ||= options[:accomplished_phases]

    unless accomplished_phases.empty?
      phases_table_width = [pdf.bounds.right]

      phases_table_header = [["<b>#{I18n.t("pdf_content.enrollment.academic_transcript.accomplished_phases")}</b>"]]

      pdf.table(phases_table_header, :column_widths => phases_table_width,
                :row_colors => ["BFBFBF"],
                :cell_style => {:font => "Courier",
                                :size => 10,
                                :inline_format => true,
                                :border_width => 0,
                                :align => :center
                }
      )

      phases_table_data = accomplished_phases.map do |accomplishment|
        [
            "#{I18n.localize(accomplishment.conclusion_date, :format => :monthyear2)} #{accomplishment.phase.name}"
        ]
      end

      pdf.table(phases_table_data, :column_widths => phases_table_width,
                :row_colors => ["F9F9F9", "F0F0F0"],
                :cell_style => {:font => "Courier",
                                :size => 8,
                                :inline_format => true,
                                :border_width => 0,
                                :align => :left
                }
      )

    end

    pdf.move_down 10
  end

  def grades_report_table(pdf, options={})
    enrollment ||= options[:enrollment]

    table_width = [68, 65, 254, 60, 60, 65]

    header = [["<b>#{I18n.t("pdf_content.enrollment.grade_list.course_year_semester")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_code")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_name")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_grade")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_credits")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.grade_list.situation")}</b>"
              ]]

    pdf.table(header, :column_widths => table_width,
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0,
                              :align => :center
              }
    )

    available_semesters = enrollment.available_semesters

    if available_semesters.any?
      table_data = []
      bold_rows = []
      total_credits = 0
      row_index = 0

      available_semesters.each do |y, s|
        class_enrollments = enrollment.class_enrollments
          .where(
            'course_classes.year' => y,
            'course_classes.semester' => s)
          .joins(:course_class)
        ys = "#{s}/#{y}"

        semester_credits = 0



        class_enrollments.each do |class_enrollment|
          row_index +=1

          table_data << [
              ys,
              class_enrollment.course_class.course.code,
              class_enrollment.course_class.course.name,
              class_enrollment.course_class.course.course_type.has_score ? number_to_grade(class_enrollment.grade) : "--",
              class_enrollment.course_class.course.credits,
              class_enrollment.situation
          ]

          semester_credits += class_enrollment.course_class.course.credits if class_enrollment.situation == I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
        end
        bold_rows<< row_index
        table_data << ["", "", "#{I18n.t("pdf_content.enrollment.grades_report.semester_summary")} ", number_to_grade(enrollment.gpr_by_semester(y, s), :precision => 1), semester_credits, ""]
        row_index+=1
        total_credits += semester_credits
      end

      pdf.table(table_data, :column_widths => table_width,
                :row_colors => ["F9F9F9", "F0F0F0"],
                :cell_style => {:font => "Courier",
                                :size => 8,
                                :inline_format => true,
                                :border_width => 0,
                                :align => :center
                }
      ) do |table|
          table.column(2).align = :left
          bold_rows.each do |i|
            table.column(2).row(i).align = :right
            table.row(i).font_style = :bold
          end
      end
    end


    footer = [
        ["", "", "#{I18n.t('pdf_content.enrollment.grades_report.total_credits')} ", "", total_credits, ""],
        ["", "", "#{I18n.t('pdf_content.enrollment.grades_report.total_gpr')} ", number_to_grade(enrollment.total_gpr, :precision => 1), "", ""]
    ]
    pdf.table(footer, :column_widths => table_width,
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0,
                              :align => :center,
                              :font_style => :bold
              }
    ) do |table|
      table.column(2).align = :right
    end

    pdf.move_down 20
  end

  def advisors_list(pdf, options={})
    enrollment ||= options[:enrollment]

    pdf.font('Courier', :size => 9) do
      height = 25
      if pdf.cursor - height < 0
        pdf.start_new_page
      end
      pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.right, :height => height) do
        pdf.stroke_bounds
        current_x = 5
        pdf.move_down 15

        pdf.draw_text("#{I18n.t("pdf_content.enrollment.grades_report.advisors")}: #{(enrollment.professors.map { |professor| professor.name }).join(", ") }", :at => [current_x, pdf.cursor])
      end
    end

    pdf.move_down 10
  end

  def thesis_table(pdf, options={})
    thesis_title ||= options[:thesis_title]
    thesis_defense_date ||= options[:thesis_defense_date]
    thesis_desense_committee ||= options[:thesis_defense_committee]

    if not(thesis_title.nil? or thesis_title.empty?)
      thesis_table_width = [pdf.bounds.right]

      thesis_table_header = [["<b>#{I18n.t("pdf_content.enrollment.thesis.header")}</b>"]]

      pdf.table(thesis_table_header, :column_widths => thesis_table_width,
                :row_colors => ["BFBFBF"],
                :cell_style => {:font => "Courier",
                                :size => 10,
                                :inline_format => true,
                                :border_width => 0,
                                :align => :center
                }
      )
      
      thesis_table_data = [
        ["<b>#{I18n.t("pdf_content.enrollment.thesis.title")}</b>", thesis_title],
        
      ]
      thesis_table_data << ["<b>#{I18n.t("pdf_content.enrollment.thesis.date")}</b>", I18n.localize(thesis_defense_date, format: :long)] unless thesis_defense_date.nil?
      table_width = [92, 480]
      pdf.table(thesis_table_data, :column_widths => table_width,
                :row_colors => ["F9F9F9", "F0F0F0"],
                :cell_style => {:font => "Courier",
                                :size => 8,
                                :inline_format => true,
                                :border_width => 0,
                                :align => :left
                }
      )

      unless thesis_desense_committee.empty?
        thesis_table_data = [
          [
            "<b>#{I18n.t("pdf_content.enrollment.thesis.defense_committee.defense_committee")}</b>",
            "<b>#{I18n.t("pdf_content.enrollment.thesis.defense_committee.name")}</b>",
            "<b>#{I18n.t("pdf_content.enrollment.thesis.defense_committee.institution")}</b>"
          ],
        ] + thesis_desense_committee.map do |professor|
          [
              "", professor.name, rescue_blank_text(professor.institution, :method_call => :name)
          ]
        end

        table_width = [92, 240, 240]

        pdf.table(thesis_table_data, :column_widths => table_width,
                  :row_colors => ["F9F9F9", "F0F0F0"],
                  :cell_style => {:font => "Courier",
                                  :size => 8,
                                  :inline_format => true,
                                  :border_width => 0,
                                  :align => :left
                  }
        ) do |table|
            table.row(0).column(1).align = :center
            table.row(0).column(2).align = :center
        end

      end
    end

    pdf.move_down 10
  end

end
