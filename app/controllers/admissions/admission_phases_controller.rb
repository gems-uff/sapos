# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhasesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionPhase" do |config|
    config.create.label = :create_admission_phase_label

    columns = [
      :name, :member_form, :shared_form, :consolidation_form, :can_edit_candidate,
      :admission_phase_committees, :form_conditions
    ]

    config.columns = columns
    config.columns[:form_conditions].show_blank_record = false

    config.columns[:member_form].form_ui = :record_select
    config.columns[:member_form].options[:params] = {
      template_type: Admissions::FormTemplate::ADMISSION_FORM
    }
    config.columns[:member_form].clear_link

    config.columns[:shared_form].form_ui = :record_select
    config.columns[:shared_form].options[:params] = {
      template_type: Admissions::FormTemplate::ADMISSION_FORM
    }
    config.columns[:shared_form].clear_link

    config.columns[:consolidation_form].form_ui = :record_select
    config.columns[:consolidation_form].options[:params] = {
      template_type: Admissions::FormTemplate::CONSOLIDATION_FORM
    }
    config.columns[:consolidation_form].clear_link

    config.actions << :duplicate
    config.duplicate.link.label = "
      <i title='#{I18n.t("active_scaffold.duplicate")}' class='fa fa-copy'></i>
    ".html_safe
    config.duplicate.link.method = :get
    config.duplicate.link.position = :after
    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, search_on: [:name], order_by: "name", full_text_search: true,
    model: "Admissions::AdmissionPhase"
  )
end
