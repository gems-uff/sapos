# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ClassSchedulesPdfHelper
  include ClassScheduleHelperConcern
  def class_schedule_table(pdf, options = {})
    course_classes ||= options[:course_classes]
    on_demand ||= options[:on_demand]
    table = prepare_class_schedule_table(
      course_classes, on_demand, used_to_render_a_pdf_report: true
    )
    table[:header][0] = table[:header][0].drop(1).collect { |h| "<b>#{h}</b>" }
    table[:data] = table[:data].collect { |row| row.drop(1) }

    table_width = [286]
    count = table[:last] - table[:first] + 1
    day_width = (320 / count).floor
    (table[:first]..table[:last]).each do |index|
      table_width << day_width
    end
    table_width << (520 - day_width * count)

    class_schedule_print_table(
        pdf, table_width, table[:header], table[:data], table[:star], true
      )
  end

  def class_schedule_print_table(pdf, table_width, header, data, star, footer)
    simple_pdf_table(pdf, table_width, header, data, {}, true) do |table|
      table.column(0).align = :left
      table.column(0).valign = :center
      table.column(0).padding = [-2, 4, 2, 4]

      table.column(-1).align = :left
      table.column(-1).valign = :center
      table.column(-1).padding = [-2, 4, 2, 4]
    end

    class_schedule_text_print(pdf, star) if footer
  end

  def class_schedule_text_print(pdf, star)
    star_text = ""
    if star
      pdf.move_down 10
      pdf.text "<b>#{star_text}* #{I18n.t(
        "activerecord.attributes.class_schedule.table.noschedule"
      )}</b>", inline_format: true
      star_text += "*"
    end

    unless CustomVariable.class_schedule_text.blank?
      pdf.move_down 5
      pdf.text "<b>#{star_text}* #{
        CustomVariable.class_schedule_text
      }</b>", inline_format: true
      # star_text += "*"
    end
  end

  def class_schedule_list_pdf(pdf, options = {})
    list = prepare_class_schedule_list(options[:course_classes], options[:on_demand])

    pdf.move_down 15
    pdf.text "<b>#{
      I18n.t("pdf_content.class_schedule.class_schedule_list.courses_offered")
    }: #{list.size}</b>", inline_format: true
    pdf.move_down 10

    list.each do |item|
      pdf.text "<b>#{item[:name]}</b>", inline_format: true
      pdf.indent(10) do
        if item[:no_schedule]
          pdf.text I18n.t(
            "activerecord.attributes.class_schedule.table.noschedule"
          )
        else
          class_schedule_day_groups(item[:allocations]).each do |group|
            pdf.text class_schedule_allocation_label(group)
          end
        end
        if item[:professor].present?
          pdf.text "#{I18n.t(
            "activerecord.attributes.class_schedule.table.professor"
          )}: #{item[:professor]}"
        end
      end
      pdf.move_down 8
    end

    unless CustomVariable.class_schedule_text.blank?
      pdf.move_down 5
      pdf.text CustomVariable.class_schedule_text
    end
  end
end
