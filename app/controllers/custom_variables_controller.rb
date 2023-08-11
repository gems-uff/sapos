# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CustomVariablesController < ApplicationController
  authorize_resource
  include ApplicationHelper
  active_scaffold :custom_variable do |config|
    config.list.sorting = { variable: "ASC" }
    config.columns[:variable].form_ui = :select
    config.columns[:variable].options = {
      options: CustomVariable::VARIABLES.keys
    }
    config.create.multipart = true
    config.update.multipart = true

    config.columns = [:variable, :value, :description]
    config.create.label = :create_custom_variable_label
    config.update.label = :update_custom_variable_label

    config.actions.exclude :deleted_records
  end
end
