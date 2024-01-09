# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportConfigsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionReportConfig" do |config|
    config.create.label = :create_admission_report_config_label
    columns = [
      :name, :form_template, :form_condition, :groups, :order
    ]

    config.columns = columns

    config.columns[:form_template].form_ui = :record_select
    config.columns[:form_template].options[:params] = {
      template_type: Admissions::FormTemplate::CONSOLIDATION_FORM
    }
    config.columns[:form_template].clear_link

    config.columns[:groups].show_blank_record = false
    config.columns[:order].show_blank_record = false
    config.columns[:order].allow_add_existing = false

    config.actions.exclude :deleted_records
  end

  protected
    def do_new
      super
      @record.init_default
    end
end
