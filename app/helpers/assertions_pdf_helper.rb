# frozen_string_literal: true

# app/helpers/assertions_pdf_helper.rb
module AssertionsPdfHelper
  include AssertionHelperConcern

  def format_text(bindings, template, template_type)
    if template_type == Assertion::ERB
      cls = ErbFormatter
    else
      cls = LiquidFormatter
    end
    formatter = cls.new(bindings)
    formatter.format(template)
  end

  def find_unique_columns(columns, rows)
    columns.select do |column|
      rows.all? { |row| row[columns.index(column)] == rows.first[columns.index(column)] }
    end
  end

  def assertion_box_text_print(pdf, template, template_type, bindings, box_width, box_height)
    pdf.move_down 30

    text = format_text(bindings, template, template_type)

    pdf.font("Times-Roman", size: 12) do
      pdf.fill_color "000000"
      lines = pdf.text_box text, at: [(pdf.bounds.width - box_width) / 2, pdf.cursor], width: box_width, height: box_height, align: :justify, inline_format: true, dry_run: true

      while lines.size > 0
        not_printed_text_length = lines.map { |line| line[:text].length }.sum
        text = text[-not_printed_text_length..-1]

        pdf.start_new_page
        lines = pdf.text_box text, at: [(pdf.bounds.width - box_width) / 2, pdf.cursor], width: box_width, height: box_height, align: :justify, inline_format: true, dry_run: true
      end
    end
  end

  def assertion_table(pdf, options = {})
    assertion = options[:assertion]
    args = assertion.args
    results = get_query_results(assertion, args)
    template = assertion.assertion_template
    template_type = assertion.template_type
    rows = results[:rows]
    columns = results[:columns]

    raise Exceptions::EmptyQueryException if rows.empty?
    
    unique_columns = find_unique_columns(columns, rows)
    bindings = {
      rows: rows,
      columns: columns
    }.merge(Hash[unique_columns.zip(rows.first.values_at(*unique_columns.map { |col| columns.index(col) }))])

    box_width = 500
    box_height = 560

    assertion_box_text_print(pdf, template, template_type, bindings, box_width, box_height)
  end
end
