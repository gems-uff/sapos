# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentsController < ApplicationController

  authorize_resource
  include NumbersHelper
  include ApplicationHelper


  active_scaffold :enrollment do |config|

    config.action_links.add 'to_pdf', :label => I18n.t('active_scaffold.to_pdf'), :page => true, :type => :collection
    config.action_links.add 'academic_transcript_pdf', :label => I18n.t('pdf_content.enrollment.academic_transcript.link'), :page => true, :type => :member

    config.list.columns = [:student, :enrollment_number, :level, :enrollment_status, :admission_date, :dismissal]
    config.list.sorting = {:enrollment_number => 'ASC'}
    config.create.label = :create_enrollment_label
    config.update.label = :update_enrollment_label
#    config.columns[:level].update_columns = :accomplishments
    config.columns[:accomplishments].allow_add_existing = false;

    config.columns.add :scholarship_durations_active, :active, :professor, :phase, :delayed_phase
    config.actions.swap :search, :field_search
    config.field_search.columns = [:enrollment_number, :student, :level, :enrollment_status, :admission_date, :active, :scholarship_durations_active, :professor, :accomplishments, :delayed_phase]

    config.columns[:enrollment_number].search_sql = "enrollments.enrollment_number"
    config.columns[:enrollment_number].search_ui = :text
    config.columns[:student].search_ui = :record_select
    config.columns[:level].search_sql = "levels.id"
    config.columns[:level].search_ui = :select
    config.columns[:enrollment_status].search_sql = "enrollment_statuses.id"
    config.columns[:enrollment_status].search_ui = :select
    config.columns[:admission_date].search_sql = "enrollments.admission_date"
    config.columns[:scholarship_durations_active].search_ui = :select
    config.columns[:scholarship_durations_active].search_sql = ""
    config.columns[:active].search_ui = :select
    config.columns[:active].search_sql = ""
    config.columns[:delayed_phase].search_sql = ""
    config.columns[:delayed_phase].search_ui = :select
    config.columns[:professor].clear_link
    config.columns[:professor].search_sql = "professors.name"
    config.columns[:professor].includes = {:advisements => :professor}
    config.columns[:professor].search_ui = :text
    config.columns[:accomplishments].search_sql = ""

    config.columns[:dismissal].sort_by :sql => 'dismissals.date'
    config.columns[:level].form_ui = :select
    config.columns[:enrollment_status].form_ui = :select
    config.columns[:dismissal].clear_link
    config.columns[:student].clear_link
    config.columns[:level].clear_link
    config.columns[:enrollment_status].clear_link
    config.columns[:admission_date].options = {:format => :monthyear}
#Student can not be configured as record select because it does not allow the user to create a new one, if needed
    config.columns[:student].form_ui = :record_select
    config.create.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :deferrals, :scholarship_durations, :dismissal, :class_enrollments]
    config.update.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :deferrals, :scholarship_durations, :dismissal, :class_enrollments]
    config.show.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :deferrals, :scholarship_durations, :dismissal]
  end
  record_select :per_page => 10, :search_on => [:enrollment_number], :order_by => 'enrollment_number', :full_text_search => true

  def self.condition_for_admission_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty? ? 1 : value[:year]

    if year != 1
      date1 = Date.new(year.to_i, month.to_i)
      date2 = Date.new(month.to_i==12 ? year.to_i + 1 : year.to_i, (month.to_i % 12) + 1)

      ["DATE(#{column.search_sql}) >= ? and DATE(#{column.search_sql}) < ?", date1, date2]
    end
  end

  def self.condition_for_scholarship_durations_active_column(column, value, like_pattern)
    query_active_scholarships = "select enrollment_id from scholarship_durations where DATE(scholarship_durations.end_date) >= DATE(?) AND  (scholarship_durations.cancel_date is NULL OR DATE(scholarship_durations.cancel_date) >= DATE(?))"
    case value
      when '0' then
        sql = "enrollments.id not in (#{query_active_scholarships})"
      when '1' then
        sql = "enrollments.id in (#{query_active_scholarships})"
      else
        sql = ""
    end

    [sql, Time.now, Time.now]
  end

  def self.condition_for_active_column(column, value, like_pattern)
    query_inactive_enrollment = "select enrollment_id from dismissals where DATE(dismissals.date) <= DATE(?)"
    case value
      when '0' then
        sql = "enrollments.id in (#{query_inactive_enrollment})"
      when '1' then
        sql = "enrollments.id not in (#{query_inactive_enrollment})"
      else
        sql = ""
    end

    [sql, Time.now]
  end

  def self.condition_for_delayed_phase_column(column, value, like_pattern)
    return "" if value[:phase].blank?
    date = value.nil? ? value : Date.parse("#{value[:year]}/#{value[:month]}/#{value[:day]}")
    phase = value[:phase] == "all" ? Phase.all : [Phase.find(value[:phase])]
    enrollments_ids = Enrollment.with_delayed_phases_on(date, phase)
    query_delayed_phase = enrollments_ids.blank? ? "1 = 2" : "enrollments.id in (#{enrollments_ids.join(',')})"
    query_delayed_phase
  end

  def self.condition_for_accomplishments_column(column, value, like_pattern)
    return "" if value[:phase].blank?
    date = value.nil? ? value : Date.parse("#{value[:year]}/#{value[:month]}/#{value[:day]}")
    phase = value[:phase] == "all" ? nil : value[:phase]
    if (value[:phase] == "all")
      enrollments_ids = Enrollment.with_all_phases_accomplished_on(date)
      query = enrollments_ids.blank? ? "1 = 2" : "enrollments.id in (#{enrollments_ids.join(',')})"
    else
      query = "enrollments.id in (select enrollment_id from accomplishments where DATE(conclusion_date) <= DATE('#{date}') and phase_id = #{phase})"
    end
    query
  end


  def to_pdf
    pdf = Prawn::Document.new

    y_position = pdf.cursor

    pdf.image("#{Rails.root}/config/images/logoIC.jpg", :at => [455, y_position],
              :vposition => :top,
              :scale => 0.3
    )

    pdf.font("Courier", :size => 14) do
      pdf.text "Universidade Federal Fluminense
                Instituto de Computação
                Pós-Graduação"
    end

    pdf.move_down 30

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

    each_record_in_page {}
    enrollments_list = find_page(:sorting => active_scaffold_config.list.user.sorting).items

    enrollments = enrollments_list.map do |enrollment|
      [
          enrollment.student[:name],
          enrollment[:enrollment_number],
          enrollment[:admission_date],
          if enrollment.dismissal
            enrollment.dismissal[:date]
          end
      ]
    end

    pdf.table(enrollments, :column_widths => [208, 108, 108, 108],
              :row_colors => ["FFFFFF", "F0F0F0"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0
              }
    )

    send_data(pdf.render, :filename => 'relatorio.pdf', :type => 'application/pdf')
  end

  def update_authorized?(record=nil)
    can? :update, record
  end

  def create_authorized?(record=nil)
    can? :create, record
  end

  def show_authorized?(record=nil)
    can? :read, record
  end

  def delete_authorized?(record=nil)
    can? :delete, record
  end

  def academic_transcript_pdf

    enrollment = Enrollment.find(params[:id])

    pdf = Prawn::Document.new(:left_margin => 20, :right_margin => 20, :top_margin => 30, :bottom_margin => 30)

    x_start_position = 5
    default_margin = 22
    default_margin_x = 50
    current_x = x_start_position
    font_width = 5.7

    pdf.image("#{Rails.root}/config/images/logoIC.jpg", :at => [pdf.bounds.right - 65, pdf.cursor],
              :vposition => :top,
              :scale => 0.3
    )
    pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.right - 85, :height => 50) do
      pdf.font('Courier', :size => 14) do
        pdf.text('Universidade Federal Fluminense
                Instituto de Computação
                Programa de Pós-Graduação em Computação', :align => :center)
      end
    end

    pdf.move_down 20

    pdf.font('Courier', :size => 15) do
      pdf.text "#{I18n.t('pdf_content.enrollment.academic_transcript.title')}", :align => :center
    end

    pdf.move_down 20
    pdf.font('Courier', :size => 9) do
      pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.right, :height => 100) do
        pdf.stroke_bounds


        first_colummn_labels_sizes = [
            I18n.t('pdf_content.enrollment.academic_transcript.student_name').size,
            I18n.t('pdf_content.enrollment.academic_transcript.enrollment_number').size,
            I18n.t('pdf_content.enrollment.academic_transcript.student_identity_number').size,
            I18n.t('pdf_content.enrollment.academic_transcript.student_cpf').size
        ]

        first_column_text_x = first_colummn_labels_sizes.sort.last*font_width + default_margin_x/3

        pdf.move_down default_margin
        pdf.draw_text("#{I18n.t('pdf_content.enrollment.academic_transcript.student_name')}:", :at => [current_x, pdf.cursor])
        pdf.draw_text("#{enrollment.student.name}", :at => [first_column_text_x, pdf.cursor])

        pdf.move_down default_margin
        enrollment_number_label = "#{I18n.t('pdf_content.enrollment.academic_transcript.enrollment_number')}:"
        pdf.draw_text(enrollment_number_label, :at => [current_x, pdf.cursor])
        enrollment_number_text = "#{enrollment.enrollment_number}"
        current_x = first_column_text_x
        pdf.draw_text(enrollment_number_text, :at => [current_x, pdf.cursor])

        current_x += enrollment_number_text.size*font_width + default_margin_x
        student_birthplace_text = "#{I18n.t('pdf_content.enrollment.academic_transcript.student_birthplace')}: #{rescue_blank_text(enrollment.student.birthplace, :name)}"
        pdf.draw_text(student_birthplace_text, :at => [current_x, pdf.cursor])

        current_x += student_birthplace_text.size*font_width + default_margin_x
        pdf.draw_text("#{I18n.t('pdf_content.enrollment.academic_transcript.student_birthdate')}: #{rescue_blank_text(enrollment.student.birthdate)}", :at => [current_x, pdf.cursor])
        pdf.move_down default_margin
        current_x = x_start_position

        student_identity_number_label = "#{I18n.t('pdf_content.enrollment.academic_transcript.student_identity_number')}:"
        pdf.draw_text(student_identity_number_label, :at => [current_x, pdf.cursor])
        student_identity_number_text = "#{rescue_blank_text(enrollment.student.identity_number)}"
        current_x = first_column_text_x
        pdf.draw_text(student_identity_number_text, :at => [current_x, pdf.cursor])

        current_x += student_identity_number_text.size*font_width + default_margin_x
        identity_issuing_body = "#{I18n.t('pdf_content.enrollment.academic_transcript.identity_issuing_body')}: #{rescue_blank_text(enrollment.student.identity_issuing_body)}"
        pdf.draw_text(identity_issuing_body, :at => [current_x, pdf.cursor])
        pdf.move_down default_margin
        current_x = x_start_position

        student_cpf_label = "#{I18n.t('pdf_content.enrollment.academic_transcript.student_cpf')}:"
        pdf.draw_text(student_cpf_label, :at => [current_x, pdf.cursor])
        student_cpf_text = "#{rescue_blank_text(enrollment.student.cpf)}"
        current_x = first_column_text_x
        pdf.draw_text(student_cpf_text, :at => [current_x, pdf.cursor])

      end
    end
    pdf.font('Courier', :size => 9) do
      pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.right, :height => 60) do
        pdf.stroke_bounds
        current_x = x_start_position
        pdf.move_down default_margin

        pdf.draw_text("#{I18n.t("pdf_content.enrollment.academic_transcript.course")}: #{enrollment.level.name} #{I18n.t("pdf_content.enrollment.academic_transcript.graduation")}", :at => [current_x, pdf.cursor])
        pdf.move_down default_margin

        pdf.draw_text("#{I18n.t("pdf_content.enrollment.academic_transcript.enrollment_admission_date")}: #{I18n.localize(enrollment.admission_date, :format => :monthyear2)}", :at => [current_x, pdf.cursor])
      end
    end


    pdf.move_down 20

    table_width = [65, 314, 60, 65, 68]

    header = [["<b>#{I18n.t("pdf_content.enrollment.academic_transcript.course_code")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.academic_transcript.course_name")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.academic_transcript.course_grade")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.academic_transcript.course_credits")}</b>",
               "<b>#{I18n.t("pdf_content.enrollment.academic_transcript.course_year_semester")}</b>"
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
    class_enrollments = enrollment.class_enrollments.where(:situation => I18n.translate("activerecord.attributes.class_enrollment.situations.aproved"))
    unless class_enrollments.empty?
      table_data = class_enrollments.map do |class_enrollment|
        [
            class_enrollment.course_class.course.code,
            class_enrollment.course_class.course.name,
            class_enrollment.course_class.course.course_type.has_score ? number_to_grade(class_enrollment.grade) : I18n.t("pdf_content.enrollment.academic_transcript.course_approved"),
            class_enrollment.course_class.course.credits,
            "#{class_enrollment.course_class.semester}/#{class_enrollment.course_class.year % 1000}"
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
        table.column(1).align = :left
      end

      footer = [["", "<b>#{I18n.t('pdf_content.enrollment.academic_transcript.total_credits')}</b>", "", class_enrollments.joins({:course_class => :course}).sum(:credits).to_i, ""]]
      pdf.table(footer, :column_widths => table_width,
                :row_colors => ["BFBFBF"],
                :cell_style => {:font => "Courier",
                                :size => 8,
                                :inline_format => true,
                                :border_width => 0,
                                :align => :center
                }
      ) do |table|
        table.column(1).align = :right
      end
    end

    pdf.move_down 20

    accomplished_phases = enrollment.accomplishments.order(:conclusion_date)

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
            "#{accomplishment.phase.name} #{I18n.localize(accomplishment.conclusion_date, :format => :monthyear2)}"
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

    pdf.font('Courier', :size => 9) do
      pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.right, :height => 25) do
        pdf.stroke_bounds
        current_x = x_start_position
        pdf.move_down 15
        pdf.draw_text("#{I18n.t("pdf_content.enrollment.academic_transcript.advisors")}: #{(enrollment.professors.map { |professor| professor.name }).join(", ") }", :at => [current_x, pdf.cursor])
      end
    end

    last_box_height = 50
    last_box_width1 = 150
    last_box_y = pdf.cursor
    pdf.font('Courier', :size => 8) do
      pdf.bounding_box([0, last_box_y], :width => last_box_width1, :height => last_box_height) do
        pdf.stroke_bounds
        current_x = x_start_position
        pdf.move_down last_box_height/2
        pdf.draw_text("#{I18n.t("pdf_content.enrollment.academic_transcript.location")}, #{I18n.localize(Date.today, :format => :long)}", :at => [current_x, pdf.cursor])
      end
    end

    last_box_width2 = 350
    pdf.font('Courier', :size => 6) do
      pdf.bounding_box([last_box_width1, last_box_y], :width => last_box_width2, :height => last_box_height) do
        pdf.stroke_bounds
        current_x = x_start_position
        pdf.move_down 8

        pdf.draw_text("#{I18n.t("pdf_content.enrollment.academic_transcript.warning1")}", :at => [current_x, pdf.cursor])

        underline_width = 3.8
        pdf.move_down 30
        underline = "__________________________________________________________________________"
        current_x += (last_box_width2 - underline.size*underline_width)/2

        pdf.draw_text(underline, :at => [current_x, pdf.cursor])

        pdf.move_down 8
        font_width = 7.5
        coordinator_signature = I18n.t("pdf_content.enrollment.academic_transcript.coordinator_signature")
        current_x += (last_box_width2 - coordinator_signature.size*font_width)/2
        pdf.draw_text(coordinator_signature, :at => [current_x, pdf.cursor])
      end
    end

    pdf.font('Courier', :size => 8) do
      pdf.bounding_box([last_box_width1 + last_box_width2, last_box_y], :width => pdf.bounds.right - last_box_width1 - last_box_width2, :height => last_box_height) do
        pdf.stroke_bounds
        current_x = x_start_position
        pdf.move_down last_box_height/2
        pdf.draw_text("#{I18n.t("pdf_content.enrollment.academic_transcript.page")} #{pdf.page_count}", :at => [current_x, pdf.cursor])
      end
    end


    send_data(pdf.render, :filename => "#{I18n.t('pdf_content.enrollment.academic_transcript.title')} -  #{enrollment.student.name}.pdf", :type => 'application/pdf')
  end


end
