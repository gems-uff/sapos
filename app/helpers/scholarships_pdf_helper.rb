# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ScholarshipsPdfHelper

  def scholarships_table(pdf, options={})
    scholarships ||= options[:scholarships]

    header = [["<b>#{I18n.t('activerecord.attributes.scholarship.scholarship_number')}</b>", 
               "<b>#{I18n.t('activerecord.attributes.scholarship.level')}</b>", 
               "<b>#{I18n.t('activerecord.attributes.scholarship.sponsor')}</b>", 
               "<b>#{I18n.t('activerecord.attributes.scholarship.scholarship_type')}</b>", 
               "<b>#{I18n.t('activerecord.attributes.scholarship.start_date')}</b>", 
               "<b>#{I18n.t('activerecord.attributes.scholarship.end_date')}</b>"]]

    pdf.table(header, :column_widths => [110, 70, 80, 70, 100, 100],
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0
              }
    )

    
    pdf.table(scholarships, :column_widths => [110, 70, 80, 70, 100, 100],
              :row_colors => ["FFFFFF", "F0F0F0"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0
              }
    )
  end

end
