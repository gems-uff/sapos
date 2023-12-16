# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionRankingResultsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionRankingResult" do |config|
    columns = [
      :ranking_config, :admission_application, :filled_form
    ]

    config.columns = columns
    config.columns[:ranking_config].actions_for_association_links = [:show]

    config.actions.exclude :deleted_records, :create, :update
  end
end
