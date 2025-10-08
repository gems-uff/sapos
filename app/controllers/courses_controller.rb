# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CoursesController < ApplicationController
  authorize_resource
  helper :course_research_areas

  active_scaffold :course do |config|
    config.actions.swap :search, :field_search
    config.create.label = :create_course_label
    config.list.sorting = { name: "ASC" }

    config.columns.add :workload_text
    config.columns = [
      :name, :code, :credits, :workload, :course_research_areas, :course_research_lines,
      :content, :course_type, :available
    ]
    config.list.columns = [
      :name, :code, :course_research_areas, :credits,
      :workload_text, :course_type, :available
    ]
    config.field_search.columns = [
      :name,
      :course_type,
      :course_research_areas,
      :course_research_lines,
      :available
    ]

    config.columns[:name].search_ui = :text
    config.columns[:course_type].form_ui = :select
    config.columns[:course_research_areas].includes = {
      course_research_areas: :research_area
    }
    config.columns[:course_research_areas].search_sql = "research_areas.name"
    config.columns[:course_research_areas].search_ui = :text

    config.columns[:course_research_lines].includes = {
      course_research_lines: :research_line
    }
    config.columns[:course_research_lines].search_sql = "research_lines.name"
    config.columns[:course_research_lines].search_ui = :text
    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, search_on: [:name], order_by: "name", full_text_search: true
  )

  def record_select_conditions_from_controller
    record_select_from_course_classes = (
      (params[:action] == "browse") &&
      (request.referer.first(
        (root_url + "course_classes").size
      ) == (root_url + "course_classes"))
    )
    if params[:available] || record_select_from_course_classes
      [Course.arel_table[:available].eq(true).to_sql]
    else
      super
    end
  end
end
