# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::ConsolidationFormFieldsController < ApplicationController
  authorize_resource :form_field
  helper "admissions/form_fields"

  active_scaffold "Admissions::FormField" do |config|
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_form_field_label


    config.columns = [
      :form_template, :order, :name, :description, :field_type,
      :configuration
    ]
    config.columns[:field_type].form_ui = :select
    config.columns[:field_type].options = {
      options: [Admissions::FormField::CODE],
      include_blank: I18n.t("active_scaffold._select_"),
      default: nil
    }

    config.actions.exclude :deleted_records
  end
end
