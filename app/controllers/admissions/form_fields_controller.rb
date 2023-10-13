# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormFieldsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::FormField" do |config|
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_form_field_label


    config.columns = [
      :form_template, :order, :name, :description, :field_type, :sync,
      :configuration
    ]
    config.columns[:field_type].form_ui = :select
    config.columns[:field_type].options = {
      options: Admissions::FormField::FIELD_TYPES,
      include_blank: I18n.t("active_scaffold._select_"),
      default: nil
    }

    config.columns[:sync].form_ui = :select
    config.columns[:sync].options = {
      options: Admissions::FormField::SYNCS,
      include_blank: true,
      default: nil
    }

    config.actions.exclude :deleted_records
  end
end
