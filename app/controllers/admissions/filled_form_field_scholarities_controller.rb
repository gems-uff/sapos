# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FilledFormFieldScholaritiesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::FilledFormFieldScholarity" do |config|
    columns = [
      :filled_form_field, :level, :status, :institution, :course,
      :location, :grade, :start_date, :end_date
    ]

    config.list.columns = columns
    config.show.columns = columns

    config.actions.exclude :deleted_records, :delete, :update, :create
  end
end
