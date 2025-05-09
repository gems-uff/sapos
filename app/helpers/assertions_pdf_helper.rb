# frozen_string_literal: true

# app/helpers/assertions_pdf_helper.rb
module AssertionsPdfHelper  
  def assertion_box_text_print(pdf, text, box_width, box_height)
    pdf.move_down 30
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
    text = assertion.format_text()
    
    box_width = 500
    box_height = 560

    assertion_box_text_print(pdf, text, box_width, box_height)
  end
end
