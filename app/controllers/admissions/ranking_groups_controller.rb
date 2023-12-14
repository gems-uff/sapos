# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingGroupsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::RankingGroup" do |config|
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_ranking_group_label
    columns = [
      :ranking_config, :name, :vacancies
    ]

    config.columns = columns

    config.actions.exclude :deleted_records
  end
end
