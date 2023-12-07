# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPendenciesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionPendency" do |config|
    columns = [
      :user, :admission_application, :admission_phase, :status, :mode
    ]

    config.columns = columns
    config.actions.exclude :deleted_records, :create, :update, :delete
  end
end
