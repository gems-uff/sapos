# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionApplicationsController < ApplicationController
  authorize_resource

  I18N_BASE = "activerecord.attributes.admissions/admission_application"

  active_scaffold "Admissions::AdmissionApplication" do |config|
    columns = [
      :admission_process, :token, :name, :email,
      :letter_requests, :filled_form,
      :admission_phase, :status
      # :results, 
    ]

    config.list.columns = columns
    config.show.columns = columns

    config.list.sorting = { admission_process: "DESC", name: "ASC" }

    config.columns.add :is_filled
    config.columns.add :custom_forms

    config.columns[:admission_process].search_ui = :record_select
    config.columns[:is_filled].search_sql = ""
    config.columns[:is_filled].search_ui = :select
    config.columns[:is_filled].options = {
      options: I18n.t("#{I18N_BASE}.is_filled_options").values,
      include_blank: I18n.t("active_scaffold._select_")
    }
    config.columns[:admission_phase].actions_for_association_links = [:show]

    config.update.columns = [:custom_forms]
    config.update.multipart = true

    config.actions.swap :search, :field_search
    config.field_search.columns = [
      :admission_process,
      :token,
      :name,
      :email,
      :is_filled,
    ]
    config.actions.exclude :deleted_records, :create
  end

  def self.condition_for_is_filled_column(column, value, like_pattern)
    filled_form = "
      select ff.id from filled_forms ff
      where ff.is_filled = 1
    "
    case value
    when I18n.t("#{I18N_BASE}.is_filled_options.true")
      ["admission_applications.filled_form_id in (#{filled_form})"]
    when I18n.t("#{I18N_BASE}.is_filled_options.false")
      ["admission_applications.filled_form_id not in (#{filled_form})"]
    else
      ""
    end
  end

  def update_authorized?(record = nil, column = nil)
    return super if record.nil?
    phase = record.admission_phase
    return false if phase.nil?
    return false if record.status == Admissions::AdmissionApplication::APPROVED
    return false if record.status == Admissions::AdmissionApplication::REPROVED

    phase.admission_committees.any? do |committee|
      committee.members.where(user_id: current_user.id).first.present?
    end && super
  end

  protected
    def before_update_save(record)
      record.filled_form.prepare_missing_fields
      phase = record.admission_phase
      record.assign_attributes(admission_application_params)
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
      if !record.valid?
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
          :_destroy
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
end
