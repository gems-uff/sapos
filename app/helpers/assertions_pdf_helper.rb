module AssertionsPdfHelper
  def common_header_part(pdf, options = {}, &block)
    data_table = yield
    pdf.indent(5) do
      text_table(pdf, data_table, 8)
    end

    pdf.move_down 5
    unless options[:hide_stroke]
      pdf.horizontal_line 0, 560
    end
  end

end