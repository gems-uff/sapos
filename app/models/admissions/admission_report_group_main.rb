# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupMain < Admissions::AdmissionReportGroupBase
  def prepare_config
    column_map = self.column_map()
    @columns = self.flat_columns(column_map)
    self.prepare_header
  end

  def prepare_group_row(row, cell_index, application, &block)
    @columns.each do |column|
      row << application.send(column[:field])
      cell_index += 1
    end
    cell_index
  end

  private
    def column_map
      result = {
        "token" => {
          header: applications_t("token"),
          mode: :application,
          field: :token
        },
        "name" => {
          header: applications_t("name"),
          mode: :application,
          field: :name
        },
        "email" => {
          header: applications_t("email"),
          mode: :application,
          field: :email
        }
      }
      result[result["token"][:header]] = result["token"]
      result[result["name"][:header]] = result["name"]
      result[result["email"][:header]] = result["email"]
      result
    end

    def flat_columns(column_map)
      report_columns = @group.columns.order(:order).map(&:name)
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
