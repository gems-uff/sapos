# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionProcessesPdfHelper
  def admission_process_pdf_t(key, **args)
    I18n.t("pdf_content.admissions/admission_process.#{key}", **args)
  end

  def form_field_t(key, **args)
    I18n.t("activerecord.attributes.admissions/form_field.#{key}", **args)
  end

  def filled_field_t(key, **args)
    key = "activerecord.attributes.admissions/filled_form_field.#{key}"
    I18n.t(key, **args)
  end

  def admission_process_pdf_title(admission_process)
    [
      ["<b>#{admission_process_pdf_t("generic.title", title: admission_process.title)}</b>"],
      ["<b>#{admission_process_pdf_t("generic.start", date: admission_process.start_date)}
        #{admission_process_pdf_t('generic.end', date: admission_process.end_date)}
        #{admission_process_pdf_t('generic.total', count: admission_process.admission_applications_count)}</b>"
      ]
    ]
  end

  def add_width(remaining_width, target, widths)
    remaining_part = remaining_width / target.size
    target.each do |index|
      widths[index] += remaining_part
    end
    (remaining_width % target.size).times do |i|
      widths[target[i]] += 1
    end
  end

  def admission_applications_table(curr_pdf, options = {})
    admission_process ||= options[:admission_process]
    admission_report_config = Admissions::AdmissionReportConfig.new.init_default
    title = admission_process_pdf_title(admission_process)
    config = admission_report_config.prepare_table(admission_process)
    config[:base_url] = request.base_url
    header = [[]]
    widths = []
    current_width = 0
    available_resize = []
    missing_width = []

    index = 0
    config[:groups].each do |group|
      next if !group.group.in_simple
      group.header.each do |column|
        width = column[:width]
        widths << (width.nil? ? 0 : width)
        missing_width << index if width.nil?
        available_resize << index if !column[:fixed_width]
        current_width += width if width.present?
        header[0] << "<b>#{column[:header]}</b>"
        index += 1
      end
    end
    data = config[:applications].map do |application|
      row = admission_report_config.prepare_row(config, application, simple: true)
      row.map { |element| element[:value] }
    end

    remaining_width = 560 - current_width
    if missing_width.present?
      add_width(remaining_width, missing_width, widths)
    elsif available_resize.present?
      add_width(remaining_width, available_resize, widths)
    elsif remaining_width != 0
      total = widths.sum
      widths = widths.map { |x| x * 560.0 / total }
    end

    curr_pdf.group do |pdf|
      pdf_table_with_title(pdf, widths, title, header, data, width: 560)
    end
  end

  def show_filled(filled, field)
    return "" if filled.blank?
    filled.to_text(
      blank: "",
      custom: {
        Admissions::FormField::FILE => ->(filled_file, _) {
          if filled_file.file.blank? || filled_file.file.file.blank?
            ""
          else
            url = download_url(filled_file.file.medium_hash)
            "<link href='#{url}'>
              #{filled_file.file.filename}
            </link>"
          end
        }
      }
    )
  end

  def admission_applications_complete_table(curr_pdf, options = {})
    admission_process ||= options[:admission_process]
    admission_report_config = Admissions::AdmissionReportConfig.new.init_default
    title = admission_process_pdf_title(admission_process)
    config = admission_report_config.prepare_table(admission_process)
    applications = config[:applications].map do |application|
      pdf_sections = []
      last_was_table = false
      config[:groups].each do |group|
        group.application_sections(application) do |filled, field, element|
          show_filled(filled, field)
        end
        group.sections.each do |section|
          section_data = group.section_to_row(section)
          if group.group.pdf_format == Admissions::AdmissionReportGroup::LIST
            pdf_sections << {
              mode: :list,
              data: [[
                section_data.map do |cell|
                  "<b>#{cell[:column][:header]}: #{cell[:value]}</b>"
                end.join("\n")
              ]]
            }
            last_was_table = false
          else
            data = []
            if !last_was_table
              last_was_table = true
              data << [
                "<b>#{form_field_t("name")}</b>",
                "<b>#{filled_field_t("value")}</b>"
              ]
            end
            data << ["<b>#{section[:title]}</b>", ""]
            section_data.each do |cell|
              data << [cell[:column][:header], cell[:value]]
            end
            pdf_sections << {
              mode: :table,
              data: data
            }
          end
        end
      end
      pdf_sections
    end

    curr_pdf.group do |pdf|
      widths = [160, 400]
      pdf_table_with_title(pdf, widths, title, "", [], width: 560)

      applications.each_with_index do |pdf_sections, index|
        pdf.start_new_page if index != 0
        pdf_sections.each do |pdf_section|
          if pdf_section[:mode] == :list
            pdf_table_with_title(pdf, widths, pdf_section[:data], "", [], width: 560)
          else
            simple_pdf_table(pdf, widths, "", pdf_section[:data], width: 560)
          end
        end
      end
    end
  end
end
