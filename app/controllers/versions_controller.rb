# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class VersionsController < ApplicationController
  authorize_resource

  active_scaffold :version do |config|
    config.columns = [:item_type, :current_object, :event, :user, :created_at]
    config.show.columns = [:item_type, :current_object, :event, :user, :old_version]
    config.search.columns = [:whodunnit, :event, :item_type, :item_id]
    config.list.sorting = { created_at: "DESC" }

    config.actions.exclude :create, :delete, :update
  end
end
