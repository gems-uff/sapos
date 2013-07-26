pdf = Prawn::Document.new(:filename => 'relatorio.pdf')
	
header(pdf)

pdf.move_down 30

advisements_table(pdf)
