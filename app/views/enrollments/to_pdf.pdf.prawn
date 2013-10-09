prawn_document(:filename => 'relatorio.pdf') do |pdf|
  header(pdf)
  document_title(pdf, I18n.t("pdf_content.enrollment.to_pdf.filename"))
  enrollments_table(pdf, :enrollments => @enrollments)
end

