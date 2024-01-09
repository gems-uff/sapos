# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupField < Admissions::AdmissionReportGroupBase
  def prepare_config
    @sections << {
      title: Admissions::AdmissionReportGroup::FIELD,
      columns: self.flat_columns({})
    }
  end

  def application_sections(application, &block)
    section = @sections[0]
    section[:application_columns] = populate_filled(
      application.try(:filled_form), section[:columns], &block
    )
  end

  private
    def flat_columns(column_map)
      template_fields = report_template_fields(admission_process.form_template)
      template_fields = template_fields.no_group
      template_fields = template_fields.no_html

      template_fields.each do |field|
        column_map[field.name] = {
          header: field.name,
          mode: :field,
          field: field
        }
      end

      report_columns = @group.columns.sort_by(&:order).map(&:name)
      if @group.operation == Admissions::AdmissionReportGroup::INCLUDE
        result = report_columns.filter_map do |name|
          column = column_map[name]
          next if column.nil?
          column
        end
      else
        result = []
        template_fields.each do |field|
          include_filtered(result, column_map, report_columns, field.name)
        end
      end
      result
    end
end
