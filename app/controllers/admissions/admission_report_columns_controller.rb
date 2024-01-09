# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportColumnsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionReportColumn" do |config|
    config.create.label = :create_admission_report_column_label
    columns = [
      :order, :name
    ]

    config.columns = columns
    config.actions.exclude :deleted_records
  end
end
