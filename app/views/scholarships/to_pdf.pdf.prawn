prawn_document(:filename => 'relatorio.pdf') do |pdf|
  header(pdf)
  document_title(pdf, I18n.t("pdf_content.scholarships.to_pdf.filename"))
  scholarships_table(pdf, scholarships: @scholarships)
end

