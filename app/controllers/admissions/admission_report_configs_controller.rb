# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportConfigsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionReportConfig" do |config|
    config.create.label = :create_admission_report_config_label
    columns = [
      :name, :form_template, :group_column_tabular, :form_condition, :groups, :ranking_columns
    ]

    config.columns = columns

    config.columns[:form_template].form_ui = :record_select
    config.columns[:form_template].options[:params] = {
      template_type: Admissions::FormTemplate::CONSOLIDATION_FORM
    }
    config.columns[:form_template].clear_link

    config.columns[:groups].show_blank_record = false
    config.columns[:ranking_columns].show_blank_record = false
    config.columns[:ranking_columns].allow_add_existing = false

    config.columns[:group_column_tabular].form_ui = :select
    config.columns[:group_column_tabular].options = {
      options: Admissions::AdmissionReportConfig::GROUP_COLUMNS
    }

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, search_on: [:name],
    full_text_search: true,
    model: "Admissions::AdmissionReportConfig"
  )

  protected
    def do_new
      super
      @record.init_default
    end
end
