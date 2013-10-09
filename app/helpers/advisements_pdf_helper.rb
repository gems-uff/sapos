# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module AdvisementsPdfHelper

  def advisements_table(pdf, options={})
    advisements ||= options[:advisements]

    header = [["<b>#{I18n.t("pdf_content.advisements.to_pdf.professor_name")}</b>",
               "<b>#{I18n.t("pdf_content.advisements.to_pdf.enrollment_number")}</b>",
               "<b>#{I18n.t("pdf_content.advisements.to_pdf.student_name")}</b>",
               "<b>#{I18n.t("pdf_content.advisements.to_pdf.level_name")}</b>"]]

    pdf.table(header, :column_widths => [135, 135, 135, 135],
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0
              }
    )
    
    pdf.table(advisements, :column_widths => [135, 135, 135, 135],
              :row_colors => ["FFFFFF", "F0F0F0"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0
              }
    )
  end

end
