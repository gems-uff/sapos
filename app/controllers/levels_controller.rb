# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class LevelsController < ApplicationController
  authorize_resource

  helper :advisement_authorizations
  active_scaffold :level do |config|
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_level_label

    config.columns = [:name, :course_name, :default_duration, :show_advisements_points_in_list, :short_name_showed_in_list_header, :advisement_authorizations]
    config.list.columns = [:name, :course_name, :default_duration, :advisement_authorizations]

    config.actions.exclude :deleted_records
  end
end
