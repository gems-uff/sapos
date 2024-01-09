# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupField < Admissions::AdmissionReportGroupBase
  def prepare_config
    @columns = self.flat_columns({})
    self.prepare_header
  end

  def prepare_group_row(row, cell_index, application, &block)
    populate_filled(
      row, cell_index, application.try(:filled_form),
      @columns, &block
    )
  end

  private
    def flat_columns(column_map)
      template_fields = report_template_fields(admission_process.form_template)
      if !@config.group_column
        template_fields = template_fields.no_group
      end
      template_fields = template_fields.no_html

      template_fields.each do |field|
        column_map[field.name] = {
          header: field.name,
          mode: :field,
          field: field
        }
      end

      report_columns = @group.columns.order(:order).map(&:name)
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
