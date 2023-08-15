# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CourseResearchAreasController < ApplicationController
  authorize_resource

  active_scaffold :course_research_area do |config|
    columns = [:course, :research_area]

    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns

    config.columns[:course].form_ui = :record_select
    config.columns[:research_area].form_ui = :record_select

    config.actions.exclude :deleted_records
  end

  record_select
end
