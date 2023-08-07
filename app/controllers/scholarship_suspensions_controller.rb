# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ScholarshipSuspensionsController < ApplicationController
  authorize_resource
  active_scaffold :"scholarship_suspension" do |config|
    config.columns[:scholarship_duration].form_ui = :record_select
    config.columns = [:scholarship_duration, :start_date, :end_date, :active]

    config.actions.exclude :deleted_records
  end
end
