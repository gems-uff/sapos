# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ScholarshipDurationsPdfHelper

  def scholarship_durations_table(pdf, options={})
    scholarship_durations ||= options[:scholarship_durations]


    header = [["<b>#{I18n.t('activerecord.attributes.scholarship_duration.scholarship')}</b>",
               "<b>#{I18n.t('activerecord.attributes.scholarship_duration.start_date')}</b>",
               "<b>#{I18n.t('activerecord.attributes.scholarship_duration.end_date')}</b>",
               "<b>#{I18n.t('activerecord.attributes.scholarship_duration.cancel_date')}</b>",
               "<b>#{I18n.t('activerecord.attributes.scholarship_duration.enrollment')}</b>"]]
    pdf.table(header, :column_widths => [108, 108, 108, 108, 108],
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0
              }
    )

    pdf.table(scholarship_durations, :column_widths => [108, 108, 108, 108, 108],
              :row_colors => ["FFFFFF", "F0F0F0"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0
              }
    )
  end

end
