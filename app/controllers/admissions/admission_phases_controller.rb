# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhasesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionPhase" do |config|
    config.create.label = :create_admission_phase_label

    list_columns = [
      :name, :member_form, :shared_form, :consolidation_form, :candidate_form, :can_edit_candidate,
      :approval_condition, :keep_in_phase_condition, :admission_phase_committees,
    ]

    form_columns = [
      :name, :member_form, :shared_form, :consolidation_form, :candidate_form, :can_edit_candidate,
      :candidate_can_edit, :candidate_can_see_member, :candidate_can_see_shared,
      :candidate_can_see_consolidation, :committee_can_see_other_individual,
      :approval_condition, :keep_in_phase_condition, :admission_phase_committees,
    ]

    config.columns = list_columns
    config.create.columns = form_columns
    config.update.columns = form_columns

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

    config.columns[:candidate_form].form_ui = :record_select
    config.columns[:candidate_form].options[:params] = {
      template_type: Admissions::FormTemplate::ADMISSION_FORM
    }
    config.columns[:candidate_form].clear_link

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
