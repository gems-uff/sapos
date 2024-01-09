# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhaseResultsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionPhaseResult" do |config|
    columns = [
      :admission_phase, :admission_application, :filled_form, :mode
    ]

    config.columns = columns
    config.columns[:admission_phase].actions_for_association_links = [:show]

    config.actions.exclude :deleted_records, :create, :update, :show, :delete
  end
end
