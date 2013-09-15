# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module EnrollmentsPdfHelper
  def enrollments_table(pdf, options={})
    enrollments ||= options[:enrollments]

    header = [["<b>#{I18n.t("activerecord.attributes.enrollment.student")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.enrollment_number")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.admission_date")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.dismissal")}</b>"]]

    pdf.table(header, :column_widths => [208, 108, 108, 108],
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0
              }
    )

    pdf.table(enrollments, :column_widths => [208, 108, 108, 108],
              :row_colors => ["FFFFFF", "F0F0F0"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0
              }
    )
  end
end
