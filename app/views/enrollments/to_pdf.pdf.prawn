prawn_document(:filename => 'relatorio.pdf') do |pdf|
    header(pdf)
    pdf.move_down 30
    enrollments_table(pdf, :enrollments => @enrollments)
end

