# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupMain < Admissions::AdmissionReportGroupBase
  def prepare_config
    return if @extra[:mode] == :letter && !@admission_process.has_letters
    @sections << {
      title: @extra[:title] || Admissions::AdmissionReportGroup::MAIN,
      columns: self.flat_columns(self.column_map()),
      disallow_group: true
    }
  end

  def application_sections(application, &block)
    return if @sections.empty?
    section = @sections[0]
    section[:application_columns] = section[:columns].map do |column|
      {
        column: column,
        value: application.send(column[:field])
      }
    end
  end

  private
    def column_map
      result = {}
      Admissions::AdmissionApplication::SHADOW_FIELDS_MAP.each do |header, field|
        result[field] = {
          header:,
          mode: :application,
          field:,
        }
        result[field][:html_class] = "fixed-col" if @extra[:fixed]
        result[header] = result[field]
      end
      result["token"].update(width: 130, fixed_width: true)
      result["name"].update(width: 150)
      result["email"].update(width: 120)
      result
    end

    def flat_columns(column_map)
      report_columns = @group.columns.sort_by(&:order).map(&:name)
      if @group.operation == Admissions::AdmissionReportGroup::INCLUDE
        result = report_columns.filter_map do |name|
          column = column_map[name]
          next if column.nil?
          column
        end
      else
        result = []
        case @extra[:mode]
        when :letter
          include_filtered(result, column_map, report_columns, "requested_letters")
          include_filtered(result, column_map, report_columns, "filled_letters")
        when :anonymous
          include_filtered(result, column_map, report_columns, "identifier")
        else
          include_filtered(result, column_map, report_columns, "token")
          include_filtered(result, column_map, report_columns, "name")
          include_filtered(result, column_map, report_columns, "email")
        end
      end
      result
    end
end
