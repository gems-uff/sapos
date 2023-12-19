# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormConditionsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::FormCondition" do |config|
    columns = [
      :mode, :field, :condition, :value, :form_conditions
    ]
    config.columns = columns
    config.columns.add :widget

    form_columns = columns + [:widget]

    config.create.columns = form_columns
    config.update.columns = form_columns

    config.columns[:mode].form_ui = :hidden
    config.columns[:field].form_ui = :hidden
    config.columns[:condition].form_ui = :hidden
    config.columns[:value].form_ui = :hidden
    config.columns[:form_conditions].form_ui = :hidden

    config.actions.exclude :deleted_records
  end
end
