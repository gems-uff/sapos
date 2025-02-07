# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_report_config, class: Admissions::AdmissionReportConfig, aliases: [
    "admissions/admission_report_config"
  ] do
    name { "Configuração de Relatório" }
    group_column_tabular { Admissions::AdmissionReportConfig::COLUMN }
  end
end
