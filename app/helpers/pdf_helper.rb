# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module PdfHelper
  include AdvisementsPdfHelper
  def header(pdf)
    y_position = pdf.cursor
    pdf.image("#{Rails.root}/config/images/logoIC.jpg", :at => [455, y_position],
              :vposition => :top,
              :scale => 0.3
    )

    pdf.font("Courier", :size => 14) do
      pdf.text "Universidade Federal Fluminense
                Instituto de Computação
                Pós-Graduação"
    end

  end

end
