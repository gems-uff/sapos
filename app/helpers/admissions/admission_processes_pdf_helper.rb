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

  def admission_applications_table(curr_pdf, options = {})
    admission_process ||= options[:admission_process]
    admission_applications = admission_process.admission_applications
    title = admission_process_pdf_title(admission_process)
    config = tabular_admission_process_config(admission_process)
    header = [config[:main_header].map { |x| "<b>#{x}</b>" }]
    data = admission_applications.order(:name).filter_map do |application|
      next if !application.filled_form.is_filled
      prepare_process_main_values(application, config).map(&:to_s)
    end

    if header[0].length == 3
      widths = [130, 230, 200]
    else
      widths = [130, 150, 120, 80, 80]
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
            "<link href='#{request.base_url}#{filled_file.file.url}'>
              #{filled_file.file.filename}
            </link>"
          end
        }
      }
    )
  end

  def admission_applications_complete_table(curr_pdf, options = {})
    admission_process ||= options[:admission_process]
    admission_applications = admission_process.admission_applications
    title = admission_process_pdf_title(admission_process)
    config = tabular_admission_process_config(admission_process, group_column: true)
    applications = admission_applications.order(:name).filter_map do |application|
      next if !application.filled_form.is_filled
      main_data = config[:main_header].zip(
        prepare_process_main_values(application, config)
      )
      app_title = [[main_data.map { |h, v| ["<b>#{h}: #{v}</b>"] }.join("\n")]]
      app_data = [
        [
          "<b>#{form_field_t("name")}</b>",
          "<b>#{filled_field_t("value")}</b>"
        ]
      ]
      populate_filled(app_data, application.filled_form, config[:template_fields], 0) do |filled, field, cell_index|
        [field.name, show_filled(filled, field)]
      end

      letters = application.letter_requests.map.with_index do |letter, i|
        ldata = [
          ["<b>#{applications_t("letter_request", count: i + 1)}</b>", ""],
          ["#{letter_request_t("name")}", "#{letter.name}"],
          ["#{letter_request_t("email")}", "#{letter.email}"],
          ["#{letter_request_t("telephone")}", "#{letter.telephone}"],
          ["#{letter_request_t("status")}", "#{letter.status}"],
        ]
        if letter.filled_form.is_filled
          populate_filled(ldata, letter.filled_form, config[:letter_fields], 0) do |filled, field, cell_index|
            [field.name, show_filled(filled, field)]
          end
        end
        {
          data: ldata
        }
      end
      {
        title: app_title,
        data: app_data,
        letters: letters
      }
    end

    curr_pdf.group do |pdf|
      widths = [160, 400]
      pdf_table_with_title(pdf, widths, title, "", [], width: 560)

      applications.each_with_index do |application, index|
        pdf.start_new_page if index != 0
        pdf_table_with_title(
          pdf, widths, application[:title], "", application[:data], width: 560
        )
        application[:letters].each do |letter|
          simple_pdf_table(pdf, widths, "", letter[:data], width: 560)
        end
      end
    end
  end
end
