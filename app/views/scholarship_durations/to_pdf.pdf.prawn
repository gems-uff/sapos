prawn_document(:filename => I18n.t("pdf_content.scholarship_durations.to_pdf.filename")) do |pdf|
  header(pdf)
  document_title(pdf, I18n.t("pdf_content.scholarship_durations.to_pdf.filename"))
  scholarship_durations_table(pdf, scholarship_durations: @scholarship_durations)
end

