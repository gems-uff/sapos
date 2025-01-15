# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_report_column, class: Admissions::AdmissionReportColumn, aliases: [
    "admissions/admission_report_column"
  ] do
    admission_report_group
    name { "coluna" }
    before(:create) do |column|
      if !Admissions::FormField.field_name_exists?(
        column.name, in_main: true, in_letter: true
      )
        FactoryBot.create(:form_field, name: column.name)
      end
    end
  end
end
