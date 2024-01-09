# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupBase
  attr_accessor :config, :group, :admission_process, :applications, :extra
  attr_accessor :sections

  def initialize(config, group, admission_process, applications, extra)
    @config = config
    @group = group
    @admission_process = admission_process
    @applications = applications
    @extra = extra
    @sections = []
  end

  def prepare_config
    self.prepare_header
  end

  def application_sections(application, &block)
  end

  def section_to_row(section)
    row = []
    if section[:application_columns].nil?
      section[:application_columns] = section[:columns].map do |column|
        {
          value: "",
          column: column
        }
      end
    end
    section[:application_columns].each do |column|
      row << column
    end
    row
  end

  def header
    row = []
    @sections.each do |section|
      if has_separator(section)
        row << {
          section: section,
          header: section[:title],
          mode: :group_column
        }
      end
      section[:columns].each do |column|
        column[:section] = section
        row << column.dup
      end
    end
    row
  end

  def prepare_group_row(application, &block)
    self.application_sections(application, &block)
    row = []
    @sections.each do |section|
      if has_separator(section)
        row << {
          value: "",
          column: {
            header: section[:title],
            mode: :group_column
          }
        }
      end
      row += self.section_to_row(section)
    end
    row
  end

  protected
    def has_separator(section)
      return false if @config.group_column_tabular != Admissions::AdmissionReportConfig::COLUMN
      !section[:disallow_group]
    end

    def include_filtered(columns, colmap, report_columns, name)
      return if report_columns.include?(name)
      result = colmap[name]
      return if result.nil?
      header = colmap[name][:header]
      return if header.present? && report_columns.include?(header)
      columns << result
    end

    def applications_t(key, **args)
      key = "activerecord.attributes.admissions/admission_application.#{key}"
      I18n.t(key, **args)
    end

    def letter_request_t(key, *args)
      I18n.t("activerecord.attributes.admissions/letter_request.#{key}", *args)
    end

    def report_template_fields(template)
      return Admissions::FormField.none if template.blank?
      template.fields.order(:order, :id).where(sync: nil)
    end

    def populate_filled(
      filled_form, columns, form_field_id: :form_field_id, field_id: :id
    )
      if filled_form.blank?
        filled_hash = {}
      else
        filled_hash = filled_form.fields.index_by(&form_field_id)
      end
      columns.map do |column|
        field = column[:field]
        filled = filled_hash[field.send(field_id)]
        element = {
          column: column
        }
        if filled.blank?
          element[:value] = ""
        else
          element[:value] = yield(filled, field, element)
        end
        element
      end
    end
end
