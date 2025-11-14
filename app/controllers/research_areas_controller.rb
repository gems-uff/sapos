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

    config.columns = [:name, :code, :professor_research_areas, :available]
    config.list.columns = [:name, :code, :research_lines, :available]
    config.show.columns.add :research_lines

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10,
    search_on: [:name],
    order_by: "name",
    full_text_search: true
  )

  def record_select_conditions_from_controller
    [ResearchArea.arel_table[:available].eq(true).to_sql]
  end
end
