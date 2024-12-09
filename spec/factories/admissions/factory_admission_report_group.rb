# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_report_group, class: Admissions::AdmissionReportGroup, aliases: [
    "admissions/admission_report_group"
  ] do
    admission_report_config
    mode { Admissions::AdmissionReportGroup::MAIN }
    pdf_format { Admissions::AdmissionReportGroup::LIST }
    operation { Admissions::AdmissionReportGroup::INCLUDE }
  end
end
