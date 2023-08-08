# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class RolesController < ApplicationController
  authorize_resource

  active_scaffold :role do |config|
    config.create.label = :create_role_label
    config.list.columns = [:id, :name, :description]
    config.columns = [:name, :description]
    config.columns[:description].form_ui = :textarea
    config.show.link = false

    config.actions.exclude :create, :delete, :update, :deleted_records
  end
end
