prawn_document(:filename => 'relatorio.pdf') do |pdf|
    header(pdf)
    pdf.move_down 20
    document_title(pdf, I18n.t('pdf_content.enrollment.academic_transcript.title'))

    


    enrollments_table(pdf, :enrollments => @enrollments)
end

