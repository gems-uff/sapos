# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportConfig < ActiveRecord::Base
  has_paper_trail

  COLUMN = record_i18n_attr("group_column_tabulars.column")
  MERGE = record_i18n_attr("group_column_tabulars.merge")
  NONE = record_i18n_attr("group_column_tabulars.none")

  GROUP_COLUMNS = [MERGE, COLUMN, NONE]


  has_many :groups, dependent: :destroy,
    class_name: "Admissions::AdmissionReportGroup"
  has_many :ranking_columns, dependent: :destroy,
    class_name: "Admissions::RankingColumn"

  belongs_to :form_template, optional: true,
    class_name: "Admissions::FormTemplate"
  belongs_to :form_condition, optional: true,
    class_name: "Admissions::FormCondition"

  validates :name, presence: true
  validates :group_column_tabular, presence: true, inclusion: { in: GROUP_COLUMNS }

  accepts_nested_attributes_for :form_condition,
    reject_if: :all_blank,
    allow_destroy: true

  def to_label
    "#{self.name}"
  end

  def init_default
    self.group_column_tabular = MERGE
    self.groups.build(
      order: 1,
      mode: Admissions::AdmissionReportGroup::MAIN,
      operation: Admissions::AdmissionReportGroup::EXCLUDE,
      in_simple: true,
      pdf_format: Admissions::AdmissionReportGroup::LIST,
    )
    self.groups.build(
      order: 2,
      mode: Admissions::AdmissionReportGroup::MAIN_LETTER,
      operation: Admissions::AdmissionReportGroup::EXCLUDE,
      in_simple: true,
      pdf_format: Admissions::AdmissionReportGroup::LIST,
    )
    self.groups.build(
      order: 3,
      mode: Admissions::AdmissionReportGroup::CONSOLIDATION,
      operation: Admissions::AdmissionReportGroup::EXCLUDE,
      pdf_format: Admissions::AdmissionReportGroup::TABLE,
    )
    self.groups.build(
      order: 4,
      mode: Admissions::AdmissionReportGroup::RANKING,
      operation: Admissions::AdmissionReportGroup::EXCLUDE,
      pdf_format: Admissions::AdmissionReportGroup::TABLE,
    )
    self.groups.build(
      order: 5,
      mode: Admissions::AdmissionReportGroup::PHASE_REVERSE,
      operation: Admissions::AdmissionReportGroup::EXCLUDE,
      pdf_format: Admissions::AdmissionReportGroup::TABLE,
    )
    self.groups.build(
      order: 6,
      mode: Admissions::AdmissionReportGroup::FIELD,
      operation: Admissions::AdmissionReportGroup::EXCLUDE,
      pdf_format: Admissions::AdmissionReportGroup::TABLE,
    )
    self.groups.build(
      order: 7,
      mode: Admissions::AdmissionReportGroup::LETTER,
      operation: Admissions::AdmissionReportGroup::EXCLUDE,
      pdf_format: Admissions::AdmissionReportGroup::TABLE,
    )
    self.ranking_columns.build(
      name: "name",
      order: Admissions::RankingColumn::ASC
    )
    self
  end

  def init_simple
    self.groups.build(
      order: 1,
      mode: Admissions::AdmissionReportGroup::MAIN,
      operation: Admissions::AdmissionReportGroup::EXCLUDE
    )
    self.groups.build(
      order: 2,
      mode: Admissions::AdmissionReportGroup::MAIN_LETTER,
      operation: Admissions::AdmissionReportGroup::EXCLUDE
    )
    self.ranking_columns.build(
      name: "name",
      order: Admissions::RankingColumn::ASC
    )
    self
  end

  def prepare_table(admission_process)
    applications = admission_process.admission_applications.filter do |application|
      next false if !application.filled_form.is_filled
      # Consolidate
      field_objects = nil
      if self.form_template.present?
        field_objects = application.fields_hash
        vars = { process: admission_process, application: application }
        filled_form = Admissions::FilledForm.new(
          is_filled: false, form_template: self.form_template
        )
        filled_form.consolidate(field_objects: field_objects, vars: vars)
        application.non_persistent = {
          filled_form: filled_form
        }
      end
      # Condition
      application.satisfies_condition(
        self.form_condition, fields: field_objects, should_raise: true
      )
    end

    if self.ranking_columns.present?
      columns = self.ranking_columns
      applications = applications.filter_map do |application|
        fields = application.fields_hash
        result = {
          __application: application,
          __fields: fields
        }
        skip = false
        columns.each do |column|
          field = column.convert(fields[column.name])
          if field.nil?
            skip = true
            break
          end
          result[column.name] = field
        end
        next if skip
        result
      end.sort do |first, second|
        Admissions::AdmissionProcessRanking.compare_candidates(columns, first, second)
      end.map do |application_hash|
        application_hash[:__application]
      end
    end

    config = {
      header: [],
      groups: [],
      applications: applications,
      admission_process: admission_process,
      base_url: ""
    }
    self.groups.each do |group|
      group_config = group.tabular_config(self, admission_process, applications)
      config[:header] += group_config.header
      config[:groups] << group_config
    end
    config
  end

  def prepare_row(config, application, simple: false, &block)
    if block.nil?
      block = ->(filled, field, element) {
        if filled.blank?
          ""
        else
          filled.to_text(
            blank: "",
            custom: {
              Admissions::FormField::FILE => ->(filled_file, _) {
                if filled_file.file.blank? || filled_file.file.file.blank?
                  ""
                else
                  "#{config[:base_url]}#{filled_file.file.url}"
                end
              }
            }
          )
        end
      }
    end
    row = []
    config[:groups].each do |group|
      next if simple && !group.group.in_simple
      row += group.prepare_group_row(application, &block)
    end
    row
  end

  def prepare_excel_row(config, application, &block)
    if block.nil?
      block = ->(filled, field, element) {
        if filled.blank?
          next ""
        end
        filled.to_text(
          blank: "",
          custom: {
            Admissions::FormField::FILE => ->(filled_file, _) {
              element[:do_not_escape] = true
              if filled_file.file.blank? || filled_file.file.file.blank?
                ""
              else
                "=HYPERLINK(\"#{config[:base_url]}#{filled_file.file.url}\",
                            \"#{config[:base_url]}#{filled_file.file.url}\")"
              end
            }
          }
        )
      }
    end
    row = self.prepare_row(config, application, &block)
    escape_formulas = row.map do |element|
      !element[:do_not_escape]
    end
    row_values = row.map { |element| element[:value] }
    {
      row: row_values,
      escape_formulas: escape_formulas
    }
  end

  def prepare_html_row(config, application, &block)
    if block.nil?
      block = ->(filled, field, element) {
        next "" if filled.blank?
        filled.to_text(
          blank: "",
          custom: {
            Admissions::FormField::FILE => ->(filled_file, _) {
              if filled_file.file.blank? || filled_file.file.file.blank?
                ""
              else
                "<a href=\"#{config[:base_url]}#{filled_file.file.url}\">
                  #{CGI.escapeHTML(filled_file.file.filename)}
                </a>".html_safe
              end
            }
          }
        )
      }
    end
    self.prepare_row(config, application, &block)
  end

  def group_column
    true
  end
end
