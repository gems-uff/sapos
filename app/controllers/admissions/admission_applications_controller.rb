# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionApplicationsController < ApplicationController
  authorize_resource

  I18N_BASE = "activerecord.attributes.admissions/admission_application"

  active_scaffold "Admissions::AdmissionApplication" do |config|
    columns = [
      :admission_process, :token, :name, :email,
      :requested_letters, :filled_letters, :letter_requests, :filled_form
    ]

    config.list.columns = columns
    config.show.columns = columns

    config.list.sorting = { admission_process: "DESC", name: "ASC" }

    config.columns.add :is_filled

    config.columns[:admission_process].search_ui = :record_select
    config.columns[:is_filled].search_sql = ""
    config.columns[:is_filled].search_ui = :select
    config.columns[:is_filled].options = {
      options: I18n.t("#{I18N_BASE}.is_filled_options").values,
      include_blank: I18n.t("active_scaffold._select_")
    }

    config.actions.swap :search, :field_search
    config.field_search.columns = [
      :admission_process,
      :token,
      :name,
      :email,
      :is_filled,
    ]
    config.actions.exclude :deleted_records, :update, :create
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
end
