# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormConditionsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::FormCondition" do |config|
    columns = [
      :field, :condition, :value, :model,
    ]
    config.columns = columns

    config.columns[:condition].form_ui = :select
    config.columns[:condition].options = {
      options: [
        "Contem",
        "Começa com",
        "Termina com",
        "=",
        ">=",
        "<=",
        ">",
        "<",
        "!=",
        "Entre",
        "Nulo",
        "Não nulo",
      ]
    }

    config.actions.exclude :deleted_records, :create, :update
  end
end
