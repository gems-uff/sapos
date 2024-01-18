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
        columns: @columns.map(&:dup),
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
      result = {}
      Admissions::LetterRequest::SHADOW_FIELDS_MAP.each do |header, field|
        result[field] = {
          header:,
          mode: :letter,
          field:,
        }
        result[header] = result[field]
      end
      result
    end

    def flat_columns(column_map)
      letter_fields = report_template_fields(@admission_process.letter_template)
      letter_fields = letter_fields.no_group
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
