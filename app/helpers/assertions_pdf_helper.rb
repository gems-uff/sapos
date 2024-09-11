# frozen_string_literal: true

# app/helpers/assertions_pdf_helper.rb
module AssertionsPdfHelper
  include AssertionHelperConcern
  def assertion_box_text_print(pdf)
    pdf.move_down 50
    text = I18n.t("activerecord.attributes.assertion.fixed")
    box_width = 400
    box_height = 100
    pdf.text_box text, at: [(pdf.bounds.width - box_width) / 2, pdf.cursor], width: box_width, height: box_height, align: :justify, inline_format: true
  end

  def assertion_table(pdf, options = {})
    assertions = options[:assertion]
    assertion_box_text_print(pdf)
    pdf.move_down 120

    results = get_avulso_results(assertions)
    rows = results[:rows]

    counter = 1
    box_width = 400
    rows.each do |row|
      pdf.text_box(
        "<b>#{counter}. Nome da disciplina: #{row[1]}</b>
        <b>Carga horária total: #{row[2]}</b>
        <b>Período: #{row[3]}.#{row[4]}</b>
        <b>Nota final: #{row[5]}</b>
        <b>Situação final: #{row[6]}</b>\n",
        at: [(pdf.bounds.width - box_width) / 2, pdf.cursor],
        width: box_width,
        align: :left,
        size: 12,
        inline_format: true
      )
      counter += 1
      pdf.move_down 80
    end

  end
end
