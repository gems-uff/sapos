# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupLetter < Admissions::AdmissionReportGroupBase
  def prepare_config
    return if !@admission_process.has_letters
    column_map = self.column_map()
    @columns = self.flat_columns(column_map)
    @max_submitted_letters = @applications.collect(&:requested_letters).max.to_i
    @max_submitted_letters.times do |i|
      @sections << {
        title: applications_t("letter_request", count: i + 1),
        columns: @columns,
        i: i + 1
      }
    end
  end

  def application_sections(application, &block)
    @sections.zip(application.letter_requests) do |section, letter|
      if letter.present?
        filled_hash = letter.filled_form.fields.index_by(&:form_field_id)
        section[:application_columns] = section[:columns].map do |column|
          element = {
            column: column
          }
          element[:value] = if column[:mode] == :letter
            letter.send(column[:field])
          else
            field = column[:field]
            filled = filled_hash[field.id]
            yield(filled, field, element)
          end
          element
        end
      else
        section[:application_columns] = section[:columns].map do |column|
          {
            column: column,
            value: ""
          }
        end
      end
    end
  end

  private
    def column_map
      result = {
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
end
