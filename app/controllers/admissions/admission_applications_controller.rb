# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionApplicationsController < ApplicationController
  authorize_resource

  I18N_BASE = "activerecord.attributes.admissions/admission_application"

  active_scaffold "Admissions::AdmissionApplication" do |config|
    config.list.columns = [
      :admission_process, :token, :name, :email, :updated_at,
      :letter_requests, :filled_form,
      :admission_phase, :status,
    ]
    config.show.columns = [
      :admission_process, :token, :name, :email,
      :admission_phase, :status,
      :filled_form, :letter_requests,
      :results, :evaluations
    ]

    config.list.sorting = { admission_process: "DESC", name: "ASC" }

    config.action_links.add "undo_consolidation",
      label: "<i title='#{
        I18n.t "active_scaffold.admissions/admission_application.undo_consolidation.title"
      }' class='fa fa-undo'></i>".html_safe,
      type: :member,
      keep_open: false,
      position: false,
      crud_type: :update,
      method: :put,
      refresh_list: true,
      ignore_method: :hide_undo_consolidation?,
      security_method: :undo_consolidation_security_method,
      confirm: I18n.t(
        "active_scaffold.admissions/admission_application.undo_consolidation.confirm"
      )

    config.columns.add :is_filled
    config.columns.add :pendency
    config.columns.add :custom_forms

    config.columns[:admission_process].search_ui = :record_select
    config.columns[:is_filled].search_sql = ""
    config.columns[:is_filled].search_ui = :select
    config.columns[:is_filled].options = {
      options: I18n.t("#{I18N_BASE}.is_filled_options").values,
      include_blank: I18n.t("active_scaffold._select_")
    }
    config.columns[:pendency].search_sql = ""
    config.columns[:pendency].search_ui = :select
    config.columns[:pendency].options = {
      options: I18n.t("#{I18N_BASE}.pendency_options").values,
      include_blank: I18n.t("active_scaffold._select_")
    }
    config.columns[:admission_phase].actions_for_association_links = [:show]
    config.columns[:admission_phase].search_ui = :record_select

    config.update.columns = [:custom_forms]
    config.update.multipart = true

    config.actions.swap :search, :field_search
    config.field_search.columns = [
      :admission_process,
      :token,
      :name,
      :email,
      :is_filled,
      :pendency,
      :admission_phase
    ]
    config.actions.exclude :deleted_records, :create
  end

  def self.condition_for_is_filled_column(column, value, like_pattern)
    filled_form = "
      select `ff`.`id` from filled_forms `ff`
      where `ff`.`is_filled` = 1
    "
    case value
    when I18n.t("#{I18N_BASE}.is_filled_options.true")
      ["`admission_applications`.`filled_form_id` in (#{filled_form})"]
    when I18n.t("#{I18N_BASE}.is_filled_options.false")
      ["`admission_applications`.`filled_form_id` not in (#{filled_form})"]
    else
      ""
    end
  end

  def self.condition_for_pendency_column(column, value, like_pattern)
    candidate_arel = Admissions::AdmissionApplication.arel_table
    pendency_arel = Admissions::AdmissionPendency.arel_table
    pendencies_query = pendency_arel.where(
      pendency_arel[:status].eq(Admissions::AdmissionPendency::PENDENT)
      .and(pendency_arel[:admission_phase_id].eq(candidate_arel[:admission_phase_id]))
    ).project(pendency_arel[:admission_application_id])
    case value
    when I18n.t("#{I18N_BASE}.pendency_options.true")
      [candidate_arel[:id].in(pendencies_query).to_sql]
    when I18n.t("#{I18N_BASE}.pendency_options.false")
      [candidate_arel[:id].not_in(pendencies_query).to_sql]
    else
      ""
    end
  end

  def update_authorized?(record = nil, column = nil)
    return super if record.nil?
    return true if can?(:override, record) && record.admission_process.staff_can_edit
    phase = record.admission_phase
    return false if phase.nil?
    return false if record.status == Admissions::AdmissionApplication::APPROVED
    return false if record.status == Admissions::AdmissionApplication::REPROVED

    phase.admission_committees.any? do |committee|
      if record.satisfies_conditions(committee.form_conditions)
        committee.members.where(user_id: current_user.id).first.present?
      end
    end && super
  end

  def hide_undo_consolidation?(record)
    eop = Admissions::AdmissionApplication::END_OF_PHASE_STATUSES
    (record.admission_phase_id.nil? && !eop.include?(record.status)) ||
      cannot?(:undo_consolidation, record) ||
      !record.admission_process.staff_can_undo
  end

  def undo_consolidation_security_method(record)
    can?(:undo_consolidation, record)
  end

  def undo_consolidation
    raise CanCan::AccessDenied.new if cannot? :undo_consolidation, Admissions::AdmissionApplication
    process_action_link_action(:undo_consolidation) do |record|
      next if hide_undo_consolidation?(record)
      eop = Admissions::AdmissionApplication::END_OF_PHASE_STATUSES
      if eop.include?(record.status)
        set_phase_id = record.admission_phase_id
      else
        phases = [nil] + record.admission_process.phases.order(:order).map do |p|
          p.admission_phase.id
        end
        index = phases.find_index(record.admission_phase_id)
        set_phase_id = phases[index - 1]
      end
      record.pendencies.where(
        status: Admissions::AdmissionPendency::PENDENT,
        admission_phase_id: record.admission_phase_id
      ).delete_all
      record.update!(
        admission_phase_id: set_phase_id,
        status: nil,
        status_message: nil,
      )
      if set_phase_id.present?
        record.results.where(
          mode: Admissions::AdmissionPhaseResult::CONSOLIDATION,
          admission_phase_id: set_phase_id
        ).delete_all
        prev_phase = Admissions::AdmissionPhase.find(set_phase_id)
        prev_phase.update_pendencies
        prev_phase_name = prev_phase.name
      else
        prev_phase_name = "Candidatura"
      end
      self.successful = true
      flash[:info] = I18n.t("active_scaffold.admissions/admission_application.undo_consolidation.success", name: prev_phase_name)
    end
  end

  protected
    def before_update_save(record)
      record.filled_form.prepare_missing_fields
      phase = record.admission_phase
      record.assign_attributes(admission_application_params)
      record.letter_requests.each do |letter_request|
        letter_request.filled_form.sync_fields_after(letter_request)
      end
      if phase.present?
        phase_forms = phase.prepare_application_forms(record, current_user, false)
        phase_forms.each do |phase_form|
          phase_form[:was_filled] = phase_form[:object].filled_form.is_filled
          phase_form[:object].filled_form.is_filled = true
        end
      else
        phase_forms = []
      end
      record.filled_form.sync_fields_after(record)
      was_filled = record.filled_form.is_filled
      record.filled_form.is_filled = true
      if record.valid?
        phase_forms.each do |phase_form|
          pendency_success = phase_form[:pendency_success]
          if pendency_success.present?
            Admissions::AdmissionPendency.where(pendency_success).update_all(
              status: Admissions::AdmissionPendency::OK
            )
          end
        end
      else
        record.filled_form.is_filled = was_filled
        phase_forms.each do |phase_form|
          phase_form[:object].filled_form.is_filled = phase_form[:was_filled]
        end
      end
    end

    def admission_application_params
      params.require(:record).permit(
        :name, :email,
        filled_form_attributes:
          Admissions::FilledFormsController.filled_form_params_definition,
        letter_requests_attributes: [
          :id, :email, :name, :telephone,
          :_destroy,
          filled_form_attributes:
            Admissions::FilledFormsController.filled_form_params_definition,
        ],
        results_attributes: [
          :id, :mode, :admission_phase_id,
          filled_form_attributes:
            Admissions::FilledFormsController.filled_form_params_definition,
        ],
        evaluations_attributes: [
          :id, :user_id, :admission_phase_id,
          filled_form_attributes:
            Admissions::FilledFormsController.filled_form_params_definition,
        ]
      )
    end

    def undo_consolidation_respond_to_html
      return_to_main
    end

    def undo_consolidation_respond_to_js
      do_refresh_list if !render_parent?
      @popstate = true
      render(action: "on_undo_consolidation")
    end

    def undo_consolidation_respond_on_iframe
      do_refresh_list if !render_parent?
      responds_to_parent do
        render action: "on_undo_consolidation", formats: [:js], layout: false
      end
    end
end
