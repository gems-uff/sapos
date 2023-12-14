# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingMachinesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::RankingMachine" do |config|
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_ranking_machine_label
    columns = [
      :name, :form_conditions
    ]

    config.columns = columns
    config.columns[:form_conditions].show_blank_record = false

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, search_on: [:name],
    full_text_search: true,
    model: "Admissions::RankingMachine"
  )
end
