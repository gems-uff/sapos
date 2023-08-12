# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ResearchAreasController < ApplicationController
  authorize_resource
  helper :professor_research_areas

  active_scaffold :research_area do |config|
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_research_area_label

    config.columns[:professor_research_areas].includes = {
      professors: :professor_research_areas
    }

    config.columns = [:name, :code, :professor_research_areas]
    config.list.columns = [:name, :code]

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10,
    search_on: [:name],
    order_by: "name",
    full_text_search: true
  )
end
