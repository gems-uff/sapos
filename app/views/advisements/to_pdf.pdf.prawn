prawn_document(:filename => 'relatorio.pdf') do |pdf|
  header(pdf)
  pdf.move_down 30
  advisements_table(pdf)
end

