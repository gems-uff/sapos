# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingProcessesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::RankingProcess" do |config|
    config.create.label = :create_ranking_process_label
    columns = [
      :ranking_config, :order, :vacancies, :group, :ranking_machine, :step
    ]

    config.columns = columns
    config.columns[:ranking_machine].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
end
