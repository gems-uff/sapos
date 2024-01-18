# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingColumnsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::RankingColumn" do |config|
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_ranking_column_label
    columns = [
      :name, :order
    ]

    config.columns[:order].form_ui = :select
    config.columns[:order].options = {
      options: Admissions::RankingColumn::ORDERS
    }


    config.columns = columns

    config.actions.exclude :deleted_records
  end
end
