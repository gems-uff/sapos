# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupMain < Admissions::AdmissionReportGroupBase
  def prepare_config
    @sections << {
      title: Admissions::AdmissionReportGroup::MAIN,
      columns: self.flat_columns(self.column_map()),
      disallow_group: true
    }
  end

  def application_sections(application, &block)
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
        "token" => {
          header: applications_t("token"),
          mode: :application,
          field: :token,
          width: 130,
          fixed_width: true,
          html_class: "fixed-col"
        },
        "name" => {
          header: applications_t("name"),
          mode: :application,
          field: :name,
          width: 150,
          html_class: "fixed-col"
        },
        "email" => {
          header: applications_t("email"),
          mode: :application,
          field: :email,
          width: 120,
          html_class: "fixed-col"
        }
      }
      result[result["token"][:header]] = result["token"]
      result[result["name"][:header]] = result["name"]
      result[result["email"][:header]] = result["email"]
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
        include_filtered(result, column_map, report_columns, "token")
        include_filtered(result, column_map, report_columns, "name")
        include_filtered(result, column_map, report_columns, "email")
      end
      result
    end
end
