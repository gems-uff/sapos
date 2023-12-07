# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhaseEvaluationsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionPhaseEvaluation" do |config|
    config.create.label = :create_admission_committee_evaluation_label
    columns = [
      :admission_phase, :user, :admission_application, :filled_form
    ]

    config.columns = columns
    config.columns[:admission_phase].actions_for_association_links = [:show]
    config.columns[:user].actions_for_association_links = [:show]

    config.actions.exclude :deleted_records, :create
  end
end
