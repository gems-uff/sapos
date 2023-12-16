# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionProcessRankingsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionProcessRanking" do |config|
    config.create.label = :create_admission_process_ranking_label
    columns = [
      :ranking_config, :admission_process, :admission_phase,
    ]
    config.columns = columns

    config.columns[:admission_phase].form_ui = :record_select
    config.columns[:ranking_config].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
end
