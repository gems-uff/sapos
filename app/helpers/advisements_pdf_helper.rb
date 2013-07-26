# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module AdvisementsPdfHelper

  def advisements_table(pdf, options={})

    header = [["<b>#{I18n.t("pdf_content.advisements.to_pdf.professor_name")}</b>",
               "<b>#{I18n.t("pdf_content.advisements.to_pdf.enrollment_number")}</b>",
               "<b>#{I18n.t("pdf_content.advisements.to_pdf.student_name")}</b>",
               "<b>#{I18n.t("pdf_content.advisements.to_pdf.level_name")}</b>"]]

    options[:header] ||= {}
    options[:header][:column_widths] ||= [135, 135, 135, 135]
    options[:header][:row_colors] ||= ["BFBFBF"]
    options[:header][:cell_style] ||= {}
    options[:header][:cell_style][:font] ||= "Courier"
    options[:header][:cell_style][:size] ||= 10
    options[:header][:cell_style][:inline_format] ||= true
    options[:header][:cell_style][:border_width] ||= 0

    pdf.table(header, options[:header])


    advs = @advisements.map do |adv|
      [
          adv.professor[:name],
          adv.enrollment[:enrollment_number],
          adv.enrollment.student[:name],
          adv.enrollment.level[:name]
      ]
    end

    options[:table] ||= {}
    options[:table][:column_widths] ||= [135, 135, 135, 135]
    options[:table][:row_colors] ||= ["FFFFFF", "F0F0F0"]
    options[:table][:cell_style] ||= {}
    options[:table][:cell_style][:font] ||= "Courier"
    options[:table][:cell_style][:size] ||= 8
    options[:table][:cell_style][:inline_format] ||= true
    options[:table][:cell_style][:border_width] ||= 0

    pdf.table(advs, options[:table])
  end

end
