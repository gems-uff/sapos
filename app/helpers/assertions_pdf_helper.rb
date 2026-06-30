# frozen_string_literal: true

# app/helpers/assertions_pdf_helper.rb
module AssertionsPdfHelper
  include PdfHelper

  def assertion_table(pdf, options = {})
    assertion = options[:assertion]
    text = assertion.format_text()
    box_width = 500
    box_height = 560 + 98
    align = options[:align] || :justify

    print_multipage_text_with_alignments(pdf, text, box_width, box_height, align, 98)
  end
end
