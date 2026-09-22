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
    actual = table[:actual].collect { |row| row.drop(1) }

    table_width = [286]
    count = table[:last] - table[:first] + 1
    day_width = (320 / count).floor
    (table[:first]..table[:last]).each do |index|
      table_width << day_width
    end
    table_width << (520 - day_width * count)

    class_schedule_print_table(
        pdf, table_width, table[:header], table[:data], table[:star], true,
        actual
      )
  end

  def class_schedule_print_table(
    pdf, table_width, header, data, star, footer, actual = nil
  )
    simple_pdf_table(pdf, table_width, header, data, {}, true) do |table|
      table.column(0).align = :left
      table.column(0).valign = :center
      table.column(0).padding = [-2, 4, 2, 4]

      table.column(-1).align = :left
      table.column(-1).valign = :center
      table.column(-1).padding = [-2, 4, 2, 4]

      apply_class_schedule_actual_text(table, actual) if actual
    end

    class_schedule_text_print(pdf, star) if footer
  end

  # Faz cada célula de dia "falar" via ActualText a frase montada em
  # prepare_class_schedule_table. O cabeçalho é a linha 0 (header: true), então
  # os dados começam na linha 1; célula sem frase (nil) fica muda.
  def apply_class_schedule_actual_text(table, actual)
    actual.each_with_index do |spoken_row, row_index|
      spoken_row.each_with_index do |phrase, col_index|
        next if phrase.nil?

        table.cells[row_index + 1, col_index].actual_text = phrase
      end
    end
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
end
