# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionPhasesHelper
  def approval_condition_form_column(record, options)
    render(partial: "admissions/form_conditions/association_widget", locals: {
      record: record,
      options: options,
      form_condition: record.approval_condition
    })
  end

  def keep_in_phase_condition_form_column(record, options)
    render(partial: "admissions/form_conditions/association_widget", locals: {
      record: record,
      options: options,
      form_condition: record.keep_in_phase_condition
    })
  end
end
