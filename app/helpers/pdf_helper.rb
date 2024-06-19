# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "prawn/measurement_extensions"

module PdfHelper
  include ApplicationHelper

  HEIGHT = 90
  FOOTER_TOP_MARGIN = 2

  def header(pdf, title, pdf_config, options = {}, &block)
    if pdf_config.nil?
      # report, transcript, grades_report, schedule
      type = options[:pdf_type] || :report
      pdf_type = :"use_at_#{type}"
      pdf_config = (
        options[:pdf_config] ||
        ReportConfiguration.where(pdf_type => true).order(order: :desc).first ||
        ReportConfiguration.new
      )
    end

    pdf.bounding_box(
      [0, pdf.cursor],
      width: pdf.bounds.left + pdf.bounds.right,
      height: HEIGHT
    ) do
      pdf.bounding_box(
        [0, pdf.cursor],
        width: pdf.bounds.left + pdf.bounds.right - 170,
        height: 68
      ) do
        pdf.stroke_bounds
        pdf.pad(15) do
          pdf.text(
            "<b>#{pdf_config.text}</b>",
            align: :center, font_size: 9, inline_format: true
          )
        end
      end

      pdf.bounding_box(
        [0, pdf.cursor - 3],
        width: pdf.bounds.left + pdf.bounds.right - 170,
        height: 19
      ) do
        pdf.stroke_bounds

        pdf.fill_color "333399"
        pdf.fill_and_stroke_rectangle(
          [pdf.bounds.left, pdf.cursor],
          pdf.bounds.left + pdf.bounds.right,
          19
        )
        pdf.fill_color "ffffff"
        pdf.pad(5) do
          pdf.text(
            "<b>#{title}</b>",
            font_size: 11, align: :center,
            inline_format: true, character_spacing: 2.4
          )
        end
        pdf.fill_color "000080"
      end

      pdf.bounding_box(
        [pdf.bounds.left + pdf.bounds.right - 153, HEIGHT],
        width: 153, height: HEIGHT
      ) do
        unless options[:hide_logo_stroke_bounds]
          pdf.stroke_bounds
        end
        unless block.nil?
          yield
        else
          if pdf_config.image.present? && pdf_config.image_identifier.present?
            pdf.image(StringIO.new(pdf_config.image.read),
              at: [pdf_config.x, HEIGHT - pdf_config.y],
              vposition: :top,
              scale: pdf_config.scale)
          else
            pdf.image("#{Rails.root}/config/images/logoUFF.jpg",
              at: [13, 77],
              vposition: :top,
              scale: 0.4
            )
          end
        end
      end
    end
  end

  def signature_footer(pdf, options = {})
    x = 5

    diff_width = options[:diff_width]
    diff_width ||= 0
    last_box_height = options[:qr_code_signature] ? 80 : 50
    last_box_width1 = 165
    last_box_width2 = 335

    last_box_y = pdf.bounds.bottom - FOOTER_TOP_MARGIN
    pdf.font("FreeMono", size: 8) do
      pdf.bounding_box(
        [0, last_box_y],
        width: last_box_width1, height: last_box_height
      ) do
        current_x = x
        if options[:qr_code_signature]
          qrcode_signature(pdf, { size: 80 })
        else
          pdf.stroke_bounds

          pdf.move_down last_box_height / 2
          pdf.draw_text(
            "#{I18n.t("pdf_content.enrollment.footer.location")}, #{I18n.localize(
              Date.today, format: :long
            )}", at: [current_x, pdf.cursor])
        end
      end
    end

    signature_font_size = options[:qr_code_signature] ? 8 : 6

    pdf.font("FreeMono", size: signature_font_size) do
      pdf.bounding_box(
        [last_box_width1, last_box_y],
        width: last_box_width2,
        height: last_box_height
      ) do
        pdf.stroke_bounds

        if options[:qr_code_signature]
          qrcode_signature_warning = I18n.t("pdf_content.enrollment.footer.qrcode_signature_warning")
          pdf.move_down last_box_height / 2 - signature_font_size / 2
          current_x = (last_box_width2 - pdf.width_of(qrcode_signature_warning)) / 2
          pdf.draw_text(
            "#{qrcode_signature_warning}",
            at: [current_x, pdf.cursor]
          )
          pdf.move_down signature_font_size
          pdf.draw_text(
            "#{I18n.t("pdf_content.enrollment.footer.signed_by_qrcode")} #{I18n.localize(Time.now, format: :defaultdatetime)} (Horário de Brasília)",
            at: [current_x, pdf.cursor]
          )
        else
          current_x = x
          pdf.move_down 8

          pdf.draw_text(
            "#{I18n.t("pdf_content.enrollment.footer.warning1")}",
            at: [current_x, pdf.cursor]
          )

          underline_width = 3.7
          pdf.move_down 30
          underline = "_" * 74
          current_x += (last_box_width2 - underline.size * underline_width) / 2

          pdf.draw_text(underline, at: [current_x, pdf.cursor])

          pdf.move_down 8
          font_width = 6.7
          coordinator_signature = I18n.t(
            "pdf_content.enrollment.footer.coordinator_signature"
          )
          current_x += (
            last_box_width2 - coordinator_signature.size * font_width
          ) / 2
          pdf.draw_text(coordinator_signature, at: [current_x, pdf.cursor])
        end
      end
    end

    pdf.font("FreeMono", size: 8) do
      pdf.bounding_box(
        [last_box_width1 + last_box_width2, last_box_y],
        width: pdf.bounds.right -
          last_box_width1 -
          last_box_width2 -
          diff_width,
        height: last_box_height
      ) do
        pdf.stroke_bounds
        current_x = x
        pdf.move_down last_box_height / 2
        pdf.draw_text(
          "#{I18n.t("pdf_content.enrollment.footer.page")} #{pdf.page_number}",
          at: [current_x, pdf.cursor]
        )
      end
    end
  end

  def datetime_footer(pdf, options = {})
    x = 5

    # diff_width = options[:diff_width]
    # diff_width ||= 0

    last_box_height = 30
    last_box_width1 = 165
    # last_box_width2 = 335

    last_box_y = pdf.bounds.bottom
    pdf.font("FreeMono", size: 8) do
      pdf.bounding_box(
        [0, last_box_y],
        width: last_box_width1,
        height: last_box_height
      ) do
        current_x = x
        pdf.move_down last_box_height / 2
        pdf.draw_text(
          "SAPOS - #{I18n.localize(Time.zone.now, format: :long)}",
          at: [current_x, pdf.cursor]
        )
      end
    end
  end

  def text_table(pdf, data_table, default_margin_indent)
    index = 0
    rows = data_table.collect { |row| "" }
    while true do
      column = data_table.collect { |row| row[index] }
      break if column.all? { |field| field.nil? }
      column_size = data_table.collect do |row|
        row[index + 1].nil? ? "" : row[index]
      end
      size = column_size.max_by { |field| field.to_s.size }.size
      column.each_with_index do |field, i|
        spaces = size >= field.to_s.size ? (" " * (size - field.to_s.size)) : ""
        rows[i] += field.to_s + spaces
      end
      index += 1
    end

    rows.each do |row|
      pdf.move_down default_margin_indent
      pdf.text(row, inline_format: true)
    end
  end


  def new_document(name, title, options = {}, &block)
    type = options[:pdf_type] || :report
    pdf_config = setup_pdf_config(type, options)

    document = prawn_document({
      page_size: "A4",
      left_margin: 0.6.cm,
      right_margin: (
        0.6.cm + ((options[:page_layout] == :landscape) ? 1.87 : 1.25)
      ),
      top_margin: 0.8.cm,
      bottom_margin: (
        pdf_config.signature_footer ? 96 + FOOTER_TOP_MARGIN : 1.cm
      ),
      filename: name
    }.merge(options)) do |pdf|
      freefont_directory = "#{Rails.root}/vendor/assets/fonts/gnu-freefont/"

      pdf.font_families.update("FreeMono" => {
        normal: freefont_directory + "FreeMono.ttf",
        bold: freefont_directory + "FreeMonoBold.ttf",
        italic: freefont_directory + "FreeMonoOblique.ttf",
        bold_italic: freefont_directory + "FreeMonoBoldOblique.ttf"
      })

      pdf.font_families.update("FreeSans" => {
        normal: freefont_directory + "FreeSans.ttf",
        bold: freefont_directory + "FreeSansBold.ttf",
        italic: freefont_directory + "FreeSansOblique.ttf",
        bold_italic: freefont_directory + "FreeSansBoldOblique.ttf"
      })

      pdf.font_families.update("FreeSerif" => {
        normal: freefont_directory + "FreeSerif.ttf",
        bold: freefont_directory + "FreeSerifBold.ttf",
        italic: freefont_directory + "FreeSerifOblique.ttf",
        bold_italic: freefont_directory + "FreeSerifBoldOblique.ttf"
      })

      pdf.fallback_fonts(["FreeSans"])

      pdf.fill_color "000080"
      pdf.stroke_color "000080"
      header(pdf, title, pdf_config)
      yield pdf

      if pdf_config.qr_code_signature
        pdf.repeat(:all, dynamic: true) do
          signature_footer(pdf, { qr_code_signature: true })
        end
      elsif pdf_config.signature_footer
        pdf.repeat(:all, dynamic: true) do
          signature_footer(pdf)
        end
      end
      pdf.repeat(:all, dynamic: true) do
        unless pdf_config.signature_footer
          datetime_footer(pdf)
        end
      end
      if options[:watermark]
        pdf.create_stamp("watermark") do
          pdf.rotate(60, origin: [0, 0]) do
            pdf.fill_color "993333"
            pdf.font("FreeMono", size: 22) do
              pdf.draw_text(
                I18n.t("pdf_content.professor_watermark"), at: [0, 0]
              )
            end
            pdf.fill_color "000000"
          end
        end
        pdf.repeat(:all, dynamic: true) do
          pdf.stamp_at "watermark", [80, 0]
        end
      end
    end

    if pdf_config.qr_code_signature && !pdf_config.preview
      uploader = PdfUploader.new
      uploader.store!({ base64_contents: Base64.encode64(document), filename: "academic_transcript.pdf" })
      uploader.file&.file&.update!(medium_hash: @qrcode_identifier)

      report = Report.new
      report.user = current_user
      report.carrierwave_file = uploader.file&.file
      report.save!
    end

    document
  end

  def pdf_list_with_title(pdf, title, data, options = {}, &block)
    width = (pdf.bounds.left + pdf.bounds.right).floor
    width = options[:width] if options.has_key? :width

    pdf_table_with_title(pdf, [width], title, [], data, options) do |table|
      table.column(0).align = :left
      table.column(0).font = "FreeMono"
      # table.column(0).size = 10
      table.column(0).padding = [2, 5]
      yield table unless block.nil?
    end
  end

  def pdf_table_with_title(
    pdf, widths, title, header, data, options = {}, &block
  )
    title_distance = 3
    title_distance = options[:title_distance] if options.has_key?(
      :title_distance
    )
    options[:distance] = 0 unless options.has_key? :distance

    # Table
    pdf.move_down title_distance
    pdf.table(title, column_widths: [widths.sum],
              width: widths.sum,
              row_colors: ["E5E5FF"],
              cell_style: { font: "FreeSans",
                            size: 9,
                            inline_format: true,
                            border_width: 1,
                            border_color: "000080",
                            align: :left,
                            padding: [2, 4]
              }
    )
    simple_pdf_table(pdf, widths, header, data, options, &block)
  end

  def simple_pdf_table(pdf, widths, header, data, options = {}, &block)
    # Header
    unless header.empty?
      pdf.table(header, column_widths: widths,
                width: widths.sum,
                row_colors: ["E5E5FF"],
                cell_style: { font: "FreeSans",
                              size: 9,
                              inline_format: true,
                              border_width: 1,
                              borders: [:top, :left, :right, :bottom],
                              border_color: "000080",
                              align: :center,
                              padding: [2, 2]
              }
      )
    end

    # Content
    unless data.empty?
      pdf.fill_color "000000"
      pdf.table(data, column_widths: widths,
                width: widths.sum,
                row_colors: ["F2F2FF", "E5E5FF"],
                cell_style: { font: "FreeSans",
                              size: 9,
                              inline_format: true,
                              border_width: 1,
                              borders: [:left, :right],
                              border_color: "000080",
                              align: :center,
                              padding: 2
                }
      ) do |table|
        table.row(0).borders = [:top, :left, :right]
        yield table unless block.nil?
      end
      pdf.fill_color "000080"
      pdf.stroke do
        pdf.horizontal_line 0, (pdf.bounds.left + pdf.bounds.right).floor
      end
    end
  end

  def qrcode_signature(pdf, options = {})
    @qrcode_identifier ||= SecureRandom.uuid + ".pdf"

    data = "#{request.protocol}#{request.host_with_port}/files/#{@qrcode_identifier}"

    pdf.print_qr_code(data, extent: options[:size] || 80, align: :center)
  end

  def setup_pdf_config(pdf_type, options)
    pdf_type_property = :"use_at_#{pdf_type}"
    options[:pdf_config] ||
      ReportConfiguration.where(pdf_type_property => true).order(order: :desc).first ||
      ReportConfiguration.new
  end
end

Prawn::Document.extensions << PdfHelper
