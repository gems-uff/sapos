# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module EnrollmentsPdfHelper

  def enrollment_student_header(pdf, options={})
    enrollment ||= options[:enrollment]
    pdf.bounding_box([0, pdf.cursor - 3], :width => 560) do
      
      pdf.font('Courier', :size => 8) do
        data_table = [
          [
            "#{I18n.t('pdf_content.enrollment.header.student_name')} " +
            "<b>#{enrollment.student.name}</b>"
          ], [
            "#{I18n.t('pdf_content.enrollment.header.enrollment_number')} " +
            "<b>#{enrollment.enrollment_number}   </b>",
            "#{I18n.t('pdf_content.enrollment.header.student_birthplace')} " +
            "<b>#{rescue_blank_text(enrollment.student.birthplace)}   </b>",
            "#{I18n.t('pdf_content.enrollment.header.student_birthdate')} " +
            "<b>#{rescue_blank_text(enrollment.student.birthdate)}</b>"
          ], [
            "#{I18n.t('pdf_content.enrollment.header.student_identity_number')} " +
            "<b>#{rescue_blank_text(enrollment.student.identity_number)}  </b>",
            "#{I18n.t('pdf_content.enrollment.header.identity_issuing_body')} " +
            "<b>#{rescue_blank_text(enrollment.student.identity_issuing_body)}  </b>",
            "#{I18n.t('pdf_content.enrollment.header.identity_issuing_place')} " +
            "<b>#{rescue_blank_text(enrollment.student.identity_issuing_place)}</b>"
          ], [
            "#{I18n.t('pdf_content.enrollment.header.student_cpf')} " +
            "<b>#{rescue_blank_text(enrollment.student.cpf)}</b>"
          ]
        ]

        pdf.indent(5) do
          text_table(pdf, data_table, 8)
        end 
        
        pdf.move_down 5
        pdf.stroke_bounds
      end
    end
  end

  def enrollment_header(pdf, options={})
    enrollment ||= options[:enrollment]
    pdf.bounding_box([0, pdf.cursor - 3], :width => 560) do
      
      pdf.font('Courier', :size => 8) do
        data_table = [
          [
            "#{I18n.t('pdf_content.enrollment.header.course')} " +
            "<b>#{rescue_blank_text(enrollment.level.name.nil? ? nil : (enrollment.level.name + I18n.t('pdf_content.enrollment.header.graduation')))}</b>"
          ], [
            "#{I18n.t('pdf_content.enrollment.header.field_of_study')} " +
            "<b>#{rescue_blank_text(enrollment.research_area, method_call: :name)}</b>"
          ], [
            "#{I18n.t('pdf_content.enrollment.header.program_level')} " +
            "<b>#{Configuration.program_level} </b>"
          ]
        ]

        pdf.indent(5) do
          text_table(pdf, data_table, 8)
        end 
        pdf.line_width 0.5
        pdf.move_down 5
        pdf.horizontal_line 0, 560

        data_table = [
          [
            "#{I18n.t('pdf_content.enrollment.header.enrollment_admission_result')} " +
            "<b>#{rescue_blank_text(enrollment.entrance_exam_result)}</b>"
          ]
        ]

        pdf.indent(5) do
          text_table(pdf, data_table, 8)
        end 


        pdf.move_down 5
        pdf.horizontal_line 0, 560

        languages = enrollment.accomplishments.joins(:phase).where(phases: {:is_language => true})
        str = "#{I18n.t('pdf_content.enrollment.header.language_tests')}:"
        unless languages.empty?
          data_table = []
          languages.each do |accomplishment|
            data_table.push([
              "#{str} " +
              "<b>#{I18n.t('pdf_content.enrollment.header.approved')} #{accomplishment.phase.name}</b>" 
            ])
            str = "|" + " "*(str.size - 1)
          end
        else
          data_table = [
            [
              "#{str} " +
              "<b>#{I18n.t('pdf_content.enrollment.header.no_test')}</b>"
            ]
          ]
        end

        pdf.indent(5) do
          text_table(pdf, data_table, 8)
        end 

        pdf.move_down 5
        pdf.horizontal_line 0, 560

        data_table = [
          [
            "#{I18n.t('pdf_content.enrollment.header.enrollment_admission_date')} " +
            "<b>#{I18n.localize(enrollment.admission_date, :format => :monthyear2)}</b>"
          ]
        ]

        pdf.indent(5) do
          text_table(pdf, data_table, 8)
        end 

        pdf.move_down 5

        if options[:show_dismissal]
          pdf.horizontal_line 0, 560

          data_table = [
            [
              "#{I18n.t('pdf_content.enrollment.header.enrollment_dismissal_date')} " +
              "<b>#{enrollment.dismissal ? " #{"#{I18n.localize(enrollment.dismissal.date, :format => :monthyear2)}"}" : "--"}</b>   ",
              "#{I18n.t('pdf_content.enrollment.header.enrollment_dismissal_reason')} " +
              "<b>#{enrollment.dismissal ? " #{enrollment.dismissal.dismissal_reason.name}" : "--"}</b>"
            ]
          ]

          pdf.indent(5) do
            text_table(pdf, data_table, 8)
          end 

          pdf.move_down 5
        end

        pdf.close_and_stroke
        pdf.line_width 1
        pdf.stroke_bounds
      end
    end
  end

  def enrollments_table(pdf, options={})
    enrollments ||= options[:enrollments]

    widths = [236, 108, 108, 108]

    header = [["<b>#{I18n.t("activerecord.attributes.enrollment.student")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.enrollment_number")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.admission_date")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.dismissal")}</b>"]]
    
    simple_pdf_table(pdf, widths, header, enrollments) do |table|
      table.column(0).align = :left
      table.column(0).padding = [2, 4]
    end
  end

  def transcript_table(pdf, options={})
    class_enrollments ||= options[:class_enrollments]
    
    table_width = [66, 280, 57, 57, 50, 50]

    #Header
    pdf.bounding_box([0, pdf.cursor - 3], :width => 560) do
    
      header = [[
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.title")}</b>"
                ]]

      pdf.table(header, :column_widths => [560],
                :row_colors => ["E5E5FF"],
                :cell_style => {:font => "Helvetica",
                                :size => 9,
                                :inline_format => true,
                                :border_width => 1,
                                :borders => [:left, :right],
                                :border_color => "000080",
                                :align => :left,
                                :padding => [2, 4]
                }
      ) 

      pdf.stroke_bounds
    end

    pdf.bounding_box([0, pdf.cursor], :width => 560) do
    
      header = [[
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_code")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_name")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_grade")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_credits")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_workload")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_year_semester")}</b>"
                ]]

      pdf.table(header, :column_widths => table_width,
                :row_colors => ["E5E5FF"],
                :cell_style => {:font => "Helvetica",
                                :size => 9,
                                :inline_format => true,
                                :border_width => 1,
                                :borders => [:left, :right],
                                :border_color => "000080",
                                :align => :center,
                                :padding => [12, 2]
                }
      ) do |table| 
        table.column(2).padding = [7, 2]
        table.column(3).padding = [2, 2]
        table.column(4).padding = [7, 2]
      end

      pdf.stroke_bounds
    end


    #Content
    unless class_enrollments.empty?
      new_page = true
      page_size = (pdf.cursor / 15.5).floor

      next_table_data = class_enrollments.map do |class_enrollment|
        [
            class_enrollment.course_class.course.code,
            class_enrollment.course_class.course.name,
            class_enrollment.course_class.course.course_type.has_score ? number_to_grade(class_enrollment.grade) : I18n.t("pdf_content.enrollment.grade_list.course_approved"),
            class_enrollment.course_class.course.credits,
            class_enrollment.course_class.course.workload_text,
            "#{class_enrollment.course_class.semester}/#{class_enrollment.course_class.year}"
        ]
      end

      #pdf.start_new_page
      while new_page do
        new_page = false;
        table_data = next_table_data


      
        pdf.bounding_box([0, pdf.cursor], :width => 560) do

          pdf.fill_color "000000" 


          if (table_data.size >= page_size) 
            new_page = true
            next_table_data = table_data.slice(page_size..-1)
            table_data = table_data.slice(0..page_size)
            page_size = 50
          end

          if (table_data.size % 2 == 0)   
            table_data.push([
              " ", "", "", "", "", ""
            ])
          end

          pdf.table(table_data, :column_widths => table_width,
                    :row_colors => ["F2F2FF", "E5E5FF"],
                    :cell_style => {:font => "Helvetica",
                                    :size => 9,
                                    :inline_format => true,
                                    :border_width => 1,
                                    :borders => [:left, :right],
                                    :border_color => "000080",
                                    :align => :center,
                                    :padding => 2
                    }
          ) do |table|
            table.column(1).align = :left
            table.column(1).font = "Helvetica"
            table.column(1).padding = [2, 4]
          end
          pdf.fill_color "000080" 
           
          pdf.stroke_bounds    
        end 
        if new_page
          pdf.start_new_page
        end
      end
    end


    #Footer
    pdf.bounding_box([0, pdf.cursor], :width => 560) do
    
      footer = [[
        "", 
        "<b>#{I18n.t('pdf_content.enrollment.grade_list.total')}</b>", 
        "", 
        class_enrollments.joins({:course_class => :course}).sum(:credits).to_i, 
        I18n.translate('activerecord.attributes.course.workload_time', :time => class_enrollments.joins({:course_class => :course}).sum(:workload).to_i),
        "" 
      ]]
      pdf.table(footer, :column_widths => table_width,
                :row_colors => ["E5E5FF"],
                :cell_style => {:font => "Helvetica",
                                :size => 9,
                                :inline_format => true,
                                :border_width => 1,
                                :borders => [:left, :right],
                                :border_color => "000080",
                                :align => :center,
                                :padding => 2
                }
      ) do |table|
        table.column(1).align = :right
        table.column(1).padding = [2, 4]
        table.column(3).text_color = "000000" 
        table.column(4).text_color = "000000" 
      end
      pdf.stroke_bounds
    end
  end

  def accomplished_table(pdf, options={})
    accomplished_phases ||= options[:accomplished_phases]

    unless accomplished_phases.empty?
      pdf.bounding_box([0, pdf.cursor - 3], :width => 560) do

        phases_table_width = [pdf.bounds.right]


        phases_table_header = [["<b>#{I18n.t("pdf_content.enrollment.academic_transcript.accomplished_phases")}</b>"]]

        pdf.table(phases_table_header, :column_widths => phases_table_width,
                  :row_colors => ["E5E5FF"],
                  :cell_style => {:font => "Courier",
                                  :size => 10,
                                  :inline_format => true,
                                  :border_width => 1,
                                  :align => :center
                  }
        )

        phases_table_data = accomplished_phases.map do |accomplishment|
          [
              "#{I18n.localize(accomplishment.conclusion_date, :format => :monthyear2)} #{accomplishment.phase.name}"
          ]
        end

        pdf.table(phases_table_data, :column_widths => phases_table_width,
                  :row_colors => ["F2F2FF", "E5E5FF"],
                  :cell_style => {:font => "Courier",
                                  :size => 10,
                                  :inline_format => true,
                                  :border_width => 0,
                                  :align => :left
                  }
        )

        pdf.stroke_bounds
      end
    end
  end

  def grades_report_table(pdf, options={})
    enrollment ||= options[:enrollment]
    total_class_enrollments ||= options[:class_enrollments]

    table_width = [66, 215, 57, 57, 50, 50, 65]

    #Header
    pdf.bounding_box([0, pdf.cursor - 3], :width => 560) do
    
      header = [[
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.title")}</b>"
                ]]

      pdf.table(header, :column_widths => [560],
                :row_colors => ["E5E5FF"],
                :cell_style => {:font => "Helvetica",
                                :size => 9,
                                :inline_format => true,
                                :border_width => 1,
                                :borders => [:left, :right],
                                :border_color => "000080",
                                :align => :left,
                                :padding => [2, 4]
                }
      ) 

      pdf.stroke_bounds
    end

    pdf.bounding_box([0, pdf.cursor], :width => 560) do
    
      header = [[
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_code")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_name")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_grade")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_credits")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_workload")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.course_year_semester")}</b>",
                 "<b>#{I18n.t("pdf_content.enrollment.grade_list.situation")}</b>"
                ]]

      pdf.table(header, :column_widths => table_width,
                :row_colors => ["E5E5FF"],
                :cell_style => {:font => "Helvetica",
                                :size => 9,
                                :inline_format => true,
                                :border_width => 1,
                                :borders => [:left, :right],
                                :border_color => "000080",
                                :align => :center,
                                :padding => [12, 2]
                }
      ) do |table| 
        table.column(2).padding = [7, 2]
        table.column(3).padding = [2, 2]
        table.column(4).padding = [7, 2]
      end

      pdf.stroke_bounds
    end

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
        semester_workload = 0


        class_enrollments.each do |class_enrollment|
          row_index +=1

          table_data << [ 
              class_enrollment.course_class.course.code,
              class_enrollment.course_class.course.name,
              class_enrollment.course_class.course.course_type.has_score ? number_to_grade(class_enrollment.grade) : "--",
              class_enrollment.course_class.course.credits,
              class_enrollment.course_class.course.workload_text,
              ys,
              class_enrollment.situation
          ]

          semester_credits += class_enrollment.course_class.course.credits if class_enrollment.situation == I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          semester_workload += class_enrollment.course_class.course.workload if class_enrollment.course_class.course.workload && class_enrollment.situation == I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
        end
        bold_rows<< row_index

        table_data << ["", "#{I18n.t("pdf_content.enrollment.grade_list.semester_summary")} ", number_to_grade(enrollment.gpr_by_semester(y, s), :precision => 1), semester_credits, I18n.translate('activerecord.attributes.course.workload_time', :time => semester_workload), "", ""]
        row_index+=1
        
        total_credits += semester_credits
      end

      next_table_data = table_data
      new_page = true
      page_size = (pdf.cursor / 15.5).floor
      current_i = 0
      next_i = page_size

      while new_page do
        new_page = false;
        table_data = next_table_data

        pdf.bounding_box([0, pdf.cursor], :width => 560) do

          pdf.fill_color "000000" 


          if (table_data.size >= page_size) 
            new_page = true
            next_table_data = table_data.slice(page_size..-1)
            table_data = table_data.slice(0..page_size)
            page_size = 50
          end

          if (table_data.size % 2 == 0)   
            table_data.push([
              " ", "", "", "", "", "", ""
            ])
          end


          pdf.table(table_data, :column_widths => table_width,
                    :row_colors => ["F2F2FF", "E5E5FF"],
                    :cell_style => {:font => "Helvetica",
                                    :size => 9,
                                    :inline_format => true,
                                    :border_width => 1,
                                    :borders => [:left, :right],
                                    :border_color => "000080",
                                    :align => :center,
                                    :padding => 2
                    }
          ) do |table|
              table.column(1).align = :left
              table.column(1).font = "Helvetica"
              table.column(1).padding = [2, 4]
              bold_rows.each do |i|
                table.column(1).row(i - current_i).align = :right
                table.row(i - current_i).font_style = :bold
              end
          end
          pdf.fill_color "000080" 
           
          pdf.stroke_bounds   
        end
        if new_page
          pdf.start_new_page
          current_i = next_i
          next_i += page_size
        end
      end
    end

    #Footer
    pdf.bounding_box([0, pdf.cursor], :width => 560) do
      footer = [
          ["", "#{I18n.t('pdf_content.enrollment.grade_list.total')} ", number_to_grade(enrollment.total_gpr, :precision => 1), total_credits, I18n.translate('activerecord.attributes.course.workload_time', :time => total_class_enrollments.joins({:course_class => :course}).sum(:workload).to_i), "", ""],
      ]
      pdf.table(footer, :column_widths => table_width,
                :row_colors => ["E5E5FF"],
                :cell_style => {:font => "Helvetica",
                                :size => 9,
                                :inline_format => true,
                                :border_width => 1,
                                :borders => [:left, :right],
                                :border_color => "000080",
                                :align => :center,
                                :padding => 2,
                                :font_style => :bold,
                                :text_color => "000000" 
                }
      ) do |table|
        table.column(1).align = :right
        table.column(1).padding = [2, 4]
        table.column(3).text_color = "000000" 
        table.column(4).text_color = "000000" 
      end
      pdf.stroke_bounds
    end
  end

  def thesis_table(pdf, options={})

    enrollment ||= options[:enrollment]

    thesis_title = enrollment.thesis_title
    thesis_defense_date = enrollment.thesis_defense_date
    thesis_desense_committee = enrollment.thesis_defense_committee_professors

    pdf.bounding_box([0, pdf.cursor], :width => 560) do
      
      pdf.font('Courier', :size => 9) do
        if not(thesis_title.nil? or thesis_title.empty?)
          data_table = [
            [
              "#{I18n.t('pdf_content.enrollment.thesis.title')} " +
              "<b>#{rescue_blank_text(thesis_title)}</b>"
            ]
          ]

          pdf.indent(5) do
            text_table(pdf, data_table, 8)
          end 
          
          pdf.move_down 5
          pdf.line_width 0.5
          pdf.horizontal_line 0, 560
          
          data_table = [
            [
              "#{I18n.t('pdf_content.enrollment.thesis.date')} " +
              "<b>#{rescue_blank_text(thesis_defense_date)}   </b>"
            ]
          ]
          if !(enrollment.dismissal.nil?)
            data_table[0].push(
              "#{I18n.t('pdf_content.enrollment.thesis.judgement')} " +
              "<b>#{rescue_blank_text(enrollment.dismissal.dismissal_reason, :method_call => :thesis_judgement)}</b>"
            )
          else
            data_table[0].push(
              "#{I18n.t('pdf_content.enrollment.thesis.judgement')} " +
              "<b>#{I18n.t("activerecord.attributes.dismissal_reason.thesis_judgements.invalid")}</b>"
            )
          end

          pdf.indent(5) do
            text_table(pdf, data_table, 8)
          end 
          
          pdf.move_down 5
          pdf.horizontal_line 0, 560
        end

        has_advisors = !(enrollment.professors.nil? || enrollment.professors.empty?)
        show_advisors = !(enrollment.dismissal.nil?) && enrollment.dismissal.dismissal_reason.show_advisor_name
        show_advisors = true if options[:show_advisors]
        if has_advisors and show_advisors
          data_table = [
            [
              "#{I18n.t('pdf_content.enrollment.thesis.advisors')} " +
              "<b>#{rescue_blank_text(enrollment.professors.collect{|a| a.name}.join(', '))}</b>"
            ]
          ]
          pdf.indent(5) do
            text_table(pdf, data_table, 8)
          end 
          
          pdf.move_down 5
          pdf.horizontal_line 0, 560
        end

        if not(thesis_desense_committee.nil? or thesis_desense_committee.empty?)
          pdf.indent(5) do
            pdf.move_down 8
            pdf.text "#{I18n.t('pdf_content.enrollment.thesis.defense_committee')} ", :inline_format => true
            pdf.move_down 5

            thesis_desense_committee.each do |professor|
              pdf.text "<b>#{professor.name} / #{rescue_blank_text(professor.institution, :method_call => :name)}</b>", :inline_format => true
              pdf.move_down 1
            end
          end
          pdf.move_down 5

          
          
        end
      end
      pdf.close_and_stroke
      pdf.line_width 1
      pdf.stroke_bounds
    end
  end

end
