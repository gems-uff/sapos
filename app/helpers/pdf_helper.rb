# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module PdfHelper
  include EnrollmentsPdfHelper
  include AdvisementsPdfHelper
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
end
