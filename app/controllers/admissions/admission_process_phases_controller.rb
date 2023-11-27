# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionProcessPhasesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionProcessPhase" do |config|
    config.create.label = :create_admission_process_phase_label
    columns = [
      :admission_process, :admission_phase, :start_date, :end_date
    ]
    config.columns = columns

    config.columns[:admission_phase].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
end
