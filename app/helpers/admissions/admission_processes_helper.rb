# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionProcessesHelper
  include PdfHelper
  include Admissions::AdmissionProcessesPdfHelper

  def admission_process_t(key, **args)
    t("activerecord.attributes.admissions/admission_process.#{key}", **args)
  end

  def applications_t(key, **args)
    key = "activerecord.attributes.admissions/admission_application.#{key}"
    I18n.t(key, **args)
  end

  def letter_request_t(key, *args)
    I18n.t("activerecord.attributes.admissions/letter_request.#{key}", *args)
  end

  def report_template_fields(template)
    return Admissions::FormTemplate.none if template.blank?
    template.fields.order(:order, :id).where(sync: nil)
  end

  def tabular_admission_process_config(
    admission_process, group_column: false
  )
    main_header = [
      applications_t("token"),
      applications_t("name"),
      applications_t("email")
    ]
    if admission_process.has_letters
      main_header += [
        applications_t("requested_letters"),
        applications_t("filled_letters")
      ]
    end

    template_fields = report_template_fields(admission_process.form_template)
    letter_fields = report_template_fields(admission_process.letter_template)
    if !group_column
      template_fields = template_fields.where.not(
        field_type: Admissions::FormField::GROUP
      )
      letter_fields = letter_fields.where.not(
        field_type: Admissions::FormField::GROUP
      )
    end
    fields_header = template_fields.map(&:name)

    letters_header = []
    applications = admission_process.admission_applications
    max_submitted_letters = applications.collect(&:requested_letters).max.to_i
    max_submitted_letters.times do |i|
      if group_column
        letters_header << applications_t("letter_request", count: i + 1)
      end
      letters_header += [
        letter_request_t("name"),
        letter_request_t("email"),
        letter_request_t("telephone"),
        letter_request_t("is_filled")
      ]
      letters_header += letter_fields.map(&:name)
    end

    {
      main_header: main_header,
      header: main_header + fields_header + letters_header,
      template_fields: template_fields,
      letter_fields: letter_fields,
      group_column: group_column,
      max_submitted_letters: max_submitted_letters,
    }
  end

  def populate_filled(row, filled_form, template_fields, cell_index)
    filled_hash = filled_form.fields.index_by(&:form_field_id)
    template_fields.each do |field|
      filled = filled_hash[field.id]
      row << yield(filled, field, cell_index)
      cell_index += 1
    end
    cell_index
  end

  def prepare_process_main_values(application, config)
    row = [
      application.token,
      application.name,
      application.email,
    ]
    if application.admission_process.has_letters
      row += [
        application.requested_letters,
        application.filled_letters,
      ]
    end
    row
  end

  def prepare_tabular_process_row(application, config, &block)
    if block.nil?
      block = ->(filled, field, cell_pos) {
        if filled.blank?
          ""
        else
          filled.to_text(
            blank: "",
            custom: {
              Admissions::FormField::FILE => ->(filled_file, _) {
                if filled_file.file.blank? || filled_file.file.file.blank?
                  ""
                else
                  "#{root_url}#{filled_file.file.url}"
                end
              }
            }
          )
        end
      }
    end

    row = prepare_process_main_values(application, config)
    cell_index = row.size
    cell_index = populate_filled(
      row, application.filled_form, config[:template_fields], cell_index, &block
    )

    application.letter_requests.each_with_index do |letter, i|
      if config[:group_column]
        row << i + 1
        cell_index += 1
      end
      row += [
        letter.name,
        letter.email,
        letter.telephone,
        letter.status
      ]
      cell_index += 4
      cell_index = populate_filled(
        row, letter.filled_form, config[:letter_fields], cell_index, &block
      )
    end
    (config[:max_submitted_letters] - application.letter_requests.count).times do
      if config[:group_column]
        row << ""
        cell_index += 1
      end
      row += [
        "",
        "",
        "",
        ""
      ]
      cell_index += 4
      letter_fields = config[:letter_fields].map { "" }
      row += letter_fields
      cell_index += letter_fields.size
    end

    row
  end

  def simple_id_column(record, column)
    link_to record.simple_id(closed_behavior: :optional_show),
      admission_url(record.simple_id)
  end

  def year_column(record, column)
    record.year.to_s
  end

  def admission_applications_show_column(record, column)
    render partial: "admission_applications_show", locals: {
      record: record, column: column
    }
  end
end
