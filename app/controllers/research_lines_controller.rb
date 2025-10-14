# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ResearchLinesController < ApplicationController
  authorize_resource

  active_scaffold :research_line do |config|
    config.actions.swap :search, :field_search
    config.field_search.columns = [
      :name,
      :research_area,
      :professors
    ]
    config.columns[:name].search_ui = :text
    config.columns[:professors].search_ui = :record_select

    config.list.sorting = { name: "ASC" }
    config.create.label = :create_research_line_label

    config.columns[:professor_research_lines].includes = {
      professors: :professor_research_lines
    }

    config.columns = [:name, :research_area, :professor_research_lines, :available]
    config.columns[:research_area].form_ui = :record_select
    config.list.columns = [:name, :research_area, :available]

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10,
    search_on: [:name],
    order_by: "name",
    full_text_search: true
  )

  def record_select_conditions_from_controller
    [ResearchLine.select(:id).joins(:research_area)
      .where(available: true)
      .where(research_areas: { available: true }).to_sql]
  end
end
