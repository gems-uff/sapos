# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupConsolidation < Admissions::AdmissionReportGroupBase
  def prepare_config
    return if @config.form_template.nil?
    @sections << {
      title: @config.form_template.name,
      columns: self.flat_columns({})
    }
  end

  def application_sections(application, &block)
    return if @sections.empty?
    section = @sections[0]
    section[:application_columns] = populate_filled(
      application.try(:non_persistent).try(:[], :filled_form),
      section[:columns], form_field_id: :form_field, field_id: :itself, &block
    )
  end

  private
    def flat_columns(column_map)
      template_fields = report_template_fields(@config.form_template)
      template_fields = template_fields.no_group
      template_fields = template_fields.no_html

      all_flat = []
      template_fields.each do |field|
        column = {
          header: field.name,
          mode: :field,
          field: field,
          names: [field.name]
        }
        (column_map[field.name] ||= []) << column
        all_flat << column
      end
      report_columns = @group.columns.sort_by(&:order).map(&:name)
      result = []
      if @group.operation == Admissions::AdmissionReportGroup::INCLUDE
        report_columns.each do |name|
          (column_map[name] || []).each do |column|
            result << column
          end
        end
      else
        result = all_flat.filter do |column|
          (column[:names] & report_columns).empty?
        end
      end
      result
    end
end
