# frozen_string_literal: true

# app/helpers/assertions_pdf_helper.rb
module AssertionsPdfHelper
  include AssertionHelperConcern

  def format_text(bindings, template)
    formatter = ErbFormatter.new(bindings)
    formatter.format(template)
  end

  def find_unique_columns(columns, rows)
    columns.select do |column|
      rows.all? { |row| row[columns.index(column)] == rows.first[columns.index(column)] }
    end
  end

  def assertion_box_text_print(pdf, template, bindings, box_width, box_height)
    pdf.move_down 30

    text = format_text(bindings, template)

    lines = pdf.text_box text, at: [(pdf.bounds.width - box_width) / 2, pdf.cursor], width: box_width, height: box_height, align: :justify, inline_format: true, dry_run: true

    while lines.size > 0
      not_printed_text_length = lines.map { |line| line[:text].length }.sum
      text = text[-not_printed_text_length..-1]

      pdf.start_new_page
      lines = pdf.text_box text, at: [(pdf.bounds.width - box_width) / 2, pdf.cursor], width: box_width, height: box_height, align: :justify, inline_format: true, dry_run: true
    end
  end

  def assertion_table(pdf, options = {})
    assertion = options[:assertion]
    args = assertion.args
    results = get_query_results(assertion, args)
    template = assertion.assertion_template
    rows = results[:rows]
    columns = results[:columns]

    if results[:rows].size == 1
      bindings = {}.merge(Hash[columns.zip(rows.first)])
    else
      unique_columns = find_unique_columns(columns, rows)
      bindings = {
        rows: rows,
        columns: columns
      }.merge(Hash[unique_columns.zip(rows.first.values_at(*unique_columns.map { |col| columns.index(col) }))])
    end

    box_width = 500
    box_height = 560

    assertion_box_text_print(pdf, template, bindings, box_width, box_height)
  end
end