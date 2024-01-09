# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupBase
  attr_accessor :config, :group, :admission_process, :applications, :extra
  attr_accessor :columns, :header

  def initialize(config, group, admission_process, applications, extra)
    @config = config
    @group = group
    @admission_process = admission_process
    @applications = applications
    @extra = extra
    @columns = []
    @header = []
  end

  def prepare_config
    self.prepare_header
  end

  def prepare_header
    @columns.each do |column|
      @header << column[:header]
    end
    self
  end

  protected
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
      row, cell_index, filled_form, columns,
      form_field_id: :form_field_id, field_id: :id
    )
      if filled_form.blank?
        filled_hash = {}
      else
        filled_hash = filled_form.fields.index_by(&form_field_id)
      end
      columns.each do |column|
        field = column[:field]
        filled = filled_hash[field.send(field_id)]
        if filled.blank?
          row << ""
        else
          row << yield(filled, field, cell_index)
        end
        cell_index += 1
      end
      cell_index
    end
end
