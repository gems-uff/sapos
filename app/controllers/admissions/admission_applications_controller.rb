# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionApplicationsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionApplication" do |config|
    columns = [
      :admission_process, :name, :email, :token,
      :requested_letters, :filled_letters, :letter_requests
    ]

    config.list.columns = columns
    config.show.columns = columns

    config.actions.exclude :deleted_records, :update, :create
  end
end
