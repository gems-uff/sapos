# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupLetter < Admissions::AdmissionReportGroupBase
  def prepare_config
    return if !@admission_process.has_letters
    column_map = self.column_map()
    flat_columns = self.flat_columns(column_map)
    @columns = self.group_columns(flat_columns)
    @max_submitted_letters = @applications.collect(&:requested_letters).max.to_i
    self.prepare_header
  end

  def prepare_header
    @columns.each do |column|
      if column[:mode] == :letters
        @max_submitted_letters.times do |i|
          if @config.group_column
            @header << applications_t("letter_request", count: i + 1)
          end
          column[:columns].each do |sub_column|
            @header << sub_column[:header]
          end
        end
      else
        @header << column[:header]
      end
    end
    self
  end

  def prepare_group_row(row, cell_index, application, &block)
    return cell_index if !@admission_process.has_letters
    @columns.each do |column|
      if column[:mode] == :letters
        application.letter_requests.each_with_index do |letter, i|
          if @config.group_column
            row << i + 1
            cell_index += 1
          end
          filled_hash = letter.filled_form.fields.index_by(&:form_field_id)
          column[:columns].each do |sub_column|
            if sub_column[:mode] == :letter
              row << letter.send(sub_column[:field])
            else
              field = sub_column[:field]
              filled = filled_hash[field.id]
              row << yield(filled, field, cell_index)
            end
            cell_index += 1
          end
        end

        (@max_submitted_letters - application.letter_requests.count).times do
          if @config.group_column
            row << ""
            cell_index += 1
          end
          column[:columns].each do |sub_column|
            row << ""
            cell_index += 1
          end
        end
      else
        row << application.send(column[:field])
        cell_index += 1
      end
    end
    cell_index
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
        },
        "name" => {
          header: letter_request_t("name"),
          mode: :letter,
          field: :name
        },
        "email" => {
          header: letter_request_t("email"),
          mode: :letter,
          field: :email
        },
        "telephone" => {
          header: letter_request_t("telephone"),
          mode: :letter,
          field: :telephone
        },
        "is_filled" => {
          header: letter_request_t("is_filled"),
          mode: :letter,
          field: :status
        }
      }
      result[result["requested_letters"][:header]] = result["requested_letters"]
      result[result["filled_letters"][:header]] = result["filled_letters"]
      result[result["name"][:header]] = result["name"]
      result[result["email"][:header]] = result["email"]
      result[result["telephone"][:header]] = result["telephone"]
      result[result["is_filled"][:header]] = result["is_filled"]
      result
    end

    def flat_columns(column_map)
      letter_fields = report_template_fields(@admission_process.letter_template)
      if !@config.group_column
        letter_fields = letter_fields.no_group
      end
      letter_fields = letter_fields.no_html

      letter_fields.each do |field|
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
        include_filtered(result, column_map, report_columns, "requested_letters")
        include_filtered(result, column_map, report_columns, "filled_letters")
        include_filtered(result, column_map, report_columns, "name")
        include_filtered(result, column_map, report_columns, "email")
        include_filtered(result, column_map, report_columns, "telephone")
        include_filtered(result, column_map, report_columns, "is_filled")
        letter_fields.each do |field|
          include_filtered(result, column_map, report_columns, field.name)
        end
      end
      result
    end

    def group_columns(flat_columns)
      columns = []
      grouped = nil
      flat_columns.each do |column|
        if column[:mode] == :application
          columns << column
        elsif grouped.nil?
          grouped = {
            columns: [column],
            mode: :letters
          }
          columns << grouped
        else
          grouped[:columns] << column
        end
      end
      columns
    end
end
