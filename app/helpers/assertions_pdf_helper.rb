# frozen_string_literal: true

# app/helpers/assertions_pdf_helper.rb
module AssertionsPdfHelper
  include AssertionHelperConcern

  def mask_cpf(cpf)
    cpf.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
  end

  def replace_placeholders(template, values, records = [])
    template = template.dup
    values.each do |key, value|
      template.gsub!("<%= var('#{key}') %>", value.to_s)
    end

    if records.any?
      record_template = template.scan(/<% records.each do \|record\| %>(.*?)<% end %>/m).flatten.first
      record_text = records.map do |record|
        record_content = record_template.dup
        record.each do |key, value|
          record_content.gsub!("<%= var('#{key}') %>", value.to_s)
        end
        record_content
      end.join("\n")
      template.gsub!(/<% records.each do \|record\| %>.*?<% end %>/m, record_text)
    end

    template
  end

  def assertion_box_text_print(pdf, template, values, records = [], box_width, box_height)
    pdf.move_down 30
    text = replace_placeholders(template, values, records)

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
    box_width = assertion.assertion_box_width
    box_height = assertion.assertion_box_height
    rows = results[:rows]
    columns = results[:columns]

    values = {
      'nome_aluno' => rows.first[columns.index('nome_aluno')],
      'cpf' => mask_cpf(rows.first[columns.index('cpf')])
    }

    records = rows.each_with_index.map do |row, index|
      record = { 'counter' => (index + 1).to_s }
      columns.each do |column|
        next if %w[nome_aluno cpf].include?(column)
        record[column] = row[columns.index(column)]
      end
      record
    end

    assertion_box_text_print(pdf, template, values, records, box_width, box_height)
  end
end
