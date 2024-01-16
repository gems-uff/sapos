# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPendenciesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionPendency" do |config|
    columns = [
      :user, :admission_application, :admission_phase, :status, :mode
    ]

    config.columns = columns

    config.columns[:user].search_ui = :record_select
    config.columns[:admission_application].search_ui = :record_select
    config.columns[:admission_phase].search_ui = :record_select
    config.columns[:status].search_ui = :select
    config.columns[:status].options = {
      options: Admissions::AdmissionPendency::STATUSES,
      include_blank: I18n.t("active_scaffold._select_")
    }

    config.columns[:mode].search_ui = :select
    config.columns[:mode].options = {
      options: Admissions::AdmissionPendency::MODES,
      include_blank: I18n.t("active_scaffold._select_")
    }

    config.actions.swap :search, :field_search
    config.field_search.columns = [
      :user,
      :admission_application,
      :admission_phase,
      :status,
      :mode,
    ]
    config.actions.exclude :deleted_records, :create, :update, :delete
  end
end
