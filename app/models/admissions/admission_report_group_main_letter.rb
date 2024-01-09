# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupMainLetter < Admissions::AdmissionReportGroupBase
  def prepare_config
    return if !@admission_process.has_letters
    @sections << {
      title: Admissions::AdmissionReportGroup::MAIN_LETTER,
      columns: self.flat_columns(self.column_map()),
      disallow_group: true,
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
      result = {
        "requested_letters" => {
          header: applications_t("requested_letters"),
          mode: :application,
          field: :requested_letters
        },
        "filled_letters" => {
          header: applications_t("filled_letters"),
          mode: :application,
          field: :filled_letters
        }
      }
      result[result["requested_letters"][:header]] = result["requested_letters"]
      result[result["filled_letters"][:header]] = result["filled_letters"]
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
        include_filtered(result, column_map, report_columns, "requested_letters")
        include_filtered(result, column_map, report_columns, "filled_letters")
      end
      result
    end
end
