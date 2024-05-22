# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AssertionsController < ApplicationController
  authorize_resource

  active_scaffold :assertion do |config|
    config.create.label = :create_assertion_label
    config.list.sorting = { name: "ASC" }
    config.columns = [:name]
    config.actions.exclude :deleted_records

    config.list.columns = [
      :document
    ]
  end



end
