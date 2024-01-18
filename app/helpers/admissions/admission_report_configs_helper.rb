# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionReportConfigsHelper
  def form_condition_form_column(record, options)
    render(partial: "admissions/form_conditions/association_widget", locals: {
      record: record,
      options: options,
      form_condition: record.form_condition
    })
  end

  def admission_report_group_t(key, **args)
    I18n.t("activerecord.attributes.admissions/admission_report_group.#{key}", **args)
  end

  def admissions_ranking_column_name_form_column(record, options)
    form_field_name_widget(record, options, text: record.name)
  end

  def admissions_admission_report_column_name_form_column(record, options)
    form_field_name_widget(record, options, text: record.name, query_options: {
      in_letter: true
    })
  end
end
