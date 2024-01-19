# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionReportGroup" do |config|
    config.create.label = :create_admission_report_group_label
    columns = [
      :admission_report_config, :order, :mode, :pdf_format, :in_simple, :operation, :columns
    ]

    config.columns = columns

    config.columns[:admission_report_config].form_ui = :record_select

    config.columns[:mode].form_ui = :select
    config.columns[:mode].options = {
      options: Admissions::AdmissionReportGroup::MODES
    }

    config.columns[:operation].form_ui = :select
    config.columns[:operation].options = {
      options: Admissions::AdmissionReportGroup::OPERATIONS
    }

    config.columns[:pdf_format].form_ui = :select
    config.columns[:pdf_format].options = {
      options: Admissions::AdmissionReportGroup::PDF_FORMATS
    }

    config.columns[:columns].show_blank_record = false

    config.actions.exclude :deleted_records
  end
end
