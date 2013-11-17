# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module PdfHelper
  
  def header(pdf)
    y_position = pdf.cursor
    pdf.image("#{Rails.root}/config/images/logoIC.jpg", :at => [pdf.bounds.right - 65, y_position],
              :vposition => :top,
              :scale => 0.3
    )

    pdf.font("Courier", :size => 14) do
      pdf.text "Universidade Federal Fluminense
                Instituto de Computação
                Programa de Pós-Graduação em Computação"
      level = Configuration.program_level
      unless level.nil?
        pdf.text "Conceito #{level} pela CAPES"
        
      end
    end

    pdf.move_down 20
  end

  def document_title(pdf, title)
    pdf.font('Courier', :size => 15) do
      pdf.text title, :align => :center
    end

    pdf.move_down 20
  end

  def page_footer(pdf, options={})
    x = 5
    last_box_height = 50
    last_box_width1 = 150
    last_box_width2 = 350

    last_box_y = pdf.bounds.bottom  #pdf.bounds.bottom + last_box_height# pdf.cursor - 15
    pdf.font('Courier', :size => 8) do
      pdf.bounding_box([0, last_box_y], :width => last_box_width1, :height => last_box_height) do
        pdf.stroke_bounds
        current_x = x
        pdf.move_down last_box_height/2
        pdf.draw_text("#{I18n.t("pdf_content.enrollment.footer.location")}, #{I18n.localize(Date.today, :format => :long)}", :at => [current_x, pdf.cursor])
      end
    end

    pdf.font('Courier', :size => 6) do
      pdf.bounding_box([last_box_width1, last_box_y], :width => last_box_width2, :height => last_box_height) do
        pdf.stroke_bounds
        current_x = x
        pdf.move_down 8

        pdf.draw_text("#{I18n.t("pdf_content.enrollment.footer.warning1")}", :at => [current_x, pdf.cursor])

        underline_width = 3.8
        pdf.move_down 30
        underline = "__________________________________________________________________________"
        current_x += (last_box_width2 - underline.size*underline_width)/2

        pdf.draw_text(underline, :at => [current_x, pdf.cursor])

        pdf.move_down 8
        font_width = 7.5
        coordinator_signature = I18n.t("pdf_content.enrollment.footer.coordinator_signature")
        current_x += (last_box_width2 - coordinator_signature.size*font_width)/2
        pdf.draw_text(coordinator_signature, :at => [current_x, pdf.cursor])
      end
    end

    pdf.font('Courier', :size => 8) do
      pdf.bounding_box([last_box_width1 + last_box_width2, last_box_y], :width => pdf.bounds.right - last_box_width1 - last_box_width2, :height => last_box_height) do
        pdf.stroke_bounds
        current_x = x
        pdf.move_down last_box_height/2
        #pdf.number_pages("#{I18n.t("pdf_content.enrollment.footer.page")} <page>/<total>")
        pdf.draw_text("#{I18n.t("pdf_content.enrollment.footer.page")} #{pdf.page_number}", :at => [current_x, pdf.cursor])
      end
    end

  end

  def text_table(pdf, data_table, default_margin_indent)
    index = 0
    rows = data_table.collect { |row| "" }
    while true do
      column = data_table.collect { |row| row[index] }
      break if column.all? { |field| field.nil? }
      column_size = data_table.collect { |row| row[index + 1].nil? ? "" : row[index] }
      size = column_size.max_by { |field| field.to_s.size }.size
      column.each_with_index do |field, i| 
        spaces = size >= field.to_s.size ? (" "*(size - field.to_s.size)) : ""
        rows[i] += field.to_s + spaces
      end
      index += 1
    end

    rows.each do |row|
      pdf.move_down default_margin_indent
    
      pdf.text(row) 
    end
  end

end
