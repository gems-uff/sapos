# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "prawn/measurement_extensions"


module PdfHelper
  
  HEIGHT = 90

  def header(pdf, title, pdf_config, options={}, &block)
    if pdf_config.nil?
      type = options[:pdf_type] || :report; #report, transcript, grades_report, schedule
      pdf_type = :"use_at_#{type}"
      pdf_config = options[:pdf_config] || ReportConfiguration.where(pdf_type => true).find(:first, :order => '`order` desc')
    end      

    pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.left + pdf.bounds.right, :height => HEIGHT) do
      pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.left + pdf.bounds.right - 170, :height => 68) do
          
          pdf.stroke_bounds
          pdf.pad(15) do
            pdf.text "<b>#{pdf_config.text}</b>", :align => :center, font_size: 9, :inline_format => true
          end
      end

      pdf.bounding_box([0, pdf.cursor - 3], :width => pdf.bounds.left + pdf.bounds.right - 170, :height => 19) do
          pdf.stroke_bounds
          
          pdf.fill_color '333399'
          pdf.fill_and_stroke_rectangle(
              [pdf.bounds.left, pdf.cursor],
              pdf.bounds.left + pdf.bounds.right,
              19 
          )
          pdf.fill_color 'ffffff'
          pdf.pad(5) do
            pdf.text "<b>#{title}</b>", font_size: 11, align: :center, :inline_format => true, character_spacing: 2.4
          end
          pdf.fill_color '000080'
      end


      pdf.bounding_box([pdf.bounds.left + pdf.bounds.right - 153, HEIGHT], :width => 153, :height => HEIGHT) do
          unless options[:hide_logo_stroke_bounds]
            pdf.stroke_bounds
          end
          unless block.nil?
            yield
          else
            if not (pdf_config.image.nil? or pdf_config.image_identifier.nil?)
              pdf.image(StringIO.new(pdf_config.image.read), 
                :at => [pdf_config.x, HEIGHT - pdf_config.y],
                :vposition => :top,
                :scale => pdf_config.scale)
            else
              pdf.image("#{Rails.root}/config/images/logoUFF.jpg", :at => [13, 77],
                :vposition => :top,
                :scale => 0.4
              )
            end
          end
      end
    end

  end

  def signature_footer(pdf, options={})
    x = 5
    
    diff_width = options[:diff_width]
    diff_width ||= 0

    last_box_height = 50
    last_box_width1 = 165
    last_box_width2 = 335

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

        underline_width = 3.7
        pdf.move_down 30
        underline = "__________________________________________________________________________"
        current_x += (last_box_width2 - underline.size*underline_width)/2

        pdf.draw_text(underline, :at => [current_x, pdf.cursor])

        pdf.move_down 8
        font_width = 6.7
        coordinator_signature = I18n.t("pdf_content.enrollment.footer.coordinator_signature")
        current_x += (last_box_width2 - coordinator_signature.size*font_width)/2
        pdf.draw_text(coordinator_signature, :at => [current_x, pdf.cursor])
      end
    end

    pdf.font('Courier', :size => 8) do
      pdf.bounding_box([last_box_width1 + last_box_width2, last_box_y], :width => pdf.bounds.right - last_box_width1 - last_box_width2 - diff_width, :height => last_box_height) do
        pdf.stroke_bounds
        current_x = x
        pdf.move_down last_box_height/2
        #pdf.number_pages("#{I18n.t("pdf_content.enrollment.footer.page")} <page>/<total>")
        pdf.draw_text("#{I18n.t("pdf_content.enrollment.footer.page")} #{pdf.page_number}", :at => [current_x, pdf.cursor])
      end
    end
  end

  def datetime_footer(pdf, options={})
    x = 5
    
    diff_width = options[:diff_width]
    diff_width ||= 0

    last_box_height = 30
    last_box_width1 = 165
    last_box_width2 = 335

    last_box_y = pdf.bounds.bottom  #pdf.bounds.bottom + last_box_height# pdf.cursor - 15
    pdf.font('Courier', :size => 8) do
      pdf.bounding_box([0, last_box_y], :width => last_box_width1, :height => last_box_height) do
        current_x = x
        pdf.move_down last_box_height/2
        pdf.draw_text("SAPOS - #{I18n.localize(Time.zone.now, :format => :long)}", :at => [current_x, pdf.cursor])
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
    
      pdf.text(row, :inline_format => true) 
    end
  end

  def no_page_break(pdf, &block)
    current_page = pdf.page_count

    roll = pdf.transaction do
      yield

      pdf.rollback if pdf.page_count > current_page
    end

    unless roll
      pdf.start_new_page
      yield
    end
  end

  def new_document(name, title, options = {}, &block)
    type = options[:pdf_type] || :report; #report, transcript, grades_report, schedule
    pdf_type = :"use_at_#{type}"
    pdf_config = options[:pdf_config] || ReportConfiguration.where(pdf_type => true).order(order: :desc).first
    
    prawn_document({
      :page_size => "A4", 
      :left_margin => 0.6.cm, 
      :right_margin => (0.6.cm + ((options[:page_layout] == :landscape) ? 1.87 : 1.25)), 
      :top_margin => 0.8.cm, 
      :bottom_margin => (pdf_config.signature_footer ? 80 : 1.cm), 
      :filename => name
    }.merge(options)) do |pdf|
      pdf.fill_color "000080" 
      pdf.stroke_color '000080'
      header(pdf, title, pdf_config)
      yield pdf
      
      pdf.repeat(:all, dynamic: true) do
        if pdf_config.signature_footer
          signature_footer(pdf)
        else
          datetime_footer(pdf)
        end
      end
      if options[:watermark]
        pdf.create_stamp("watermark") do
          pdf.rotate(60, :origin => [0, 0]) do
           pdf.fill_color "993333"
           pdf.font('Courier', :size => 22) do
             pdf.draw_text I18n.t('pdf_content.professor_watermark'), :at => [0, 0]
           end
           pdf.fill_color "000000"
          end
        end
        pdf.repeat(:all, dynamic: true) do
          pdf.stamp_at "watermark", [80, 0] 
        end
      end
    end
  end

  def simple_pdf_table(pdf, widths, header, values, options={}, &block)
    distance = 3
    distance = options[:distance] if options.has_key? :distance

    #Header
    pdf.bounding_box([0, pdf.cursor - distance], :width => (pdf.bounds.left + pdf.bounds.right).floor) do
    
      pdf.table(header, :column_widths => widths,
                :row_colors => ["E5E5FF"],
                :cell_style => {:font => "Helvetica",
                                :size => 9,
                                :inline_format => true,
                                :border_width => 1,
                                :borders => [:left, :right],
                                :border_color => "000080",
                                :align => :center,
                                :padding => [2, 2]
              }
      )

      pdf.stroke_bounds

    end

    #Content
    unless values.empty?
      pdf.table(values, :column_widths => widths,
                :row_colors => ["F2F2FF", "E5E5FF"],
                :cell_style => {:font => "Helvetica",
                                :size => 9,
                                :inline_format => true,
                                :border_width => 1,
                                :borders => [:left, :right],
                                :border_color => "000080",
                                :align => :center,
                                :padding => 2
                }
      ) do |table| 
        table.row(0).borders = [:top, :left, :right]
        yield table unless block.nil?
        
      end
      pdf.stroke do
        pdf.horizontal_line 0, (pdf.bounds.left + pdf.bounds.right).floor
      end
    end
    
  end

end
