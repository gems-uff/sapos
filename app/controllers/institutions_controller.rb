# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class InstitutionsController < ApplicationController
  authorize_resource

  active_scaffold :institution do |config|
    config.list.sorting = { name: "ASC" }
    config.list.columns = [:name, :code]
    config.create.label = :create_institution_label
    config.columns = [:name, :code, :majors]
    config.columns[:majors].associated_limit = nil
    config.columns[:majors].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10,
    search_on: [:name],
    order_by: "name",
    full_text_search: true
  )
end
