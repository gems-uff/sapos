# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhaseCommitteesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionPhaseCommittee" do |config|
    config.create.label = :create_admission_phase_committee_label
    columns = [
      :admission_phase, :admission_committee
    ]
    config.columns = columns
    config.columns[:admission_committee].form_ui = :record_select
    config.columns[:admission_phase].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
end
