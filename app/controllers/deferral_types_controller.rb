# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class DeferralTypesController < ApplicationController
  authorize_resource

  active_scaffold :deferral_type do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :description, :duration_semesters, :duration_months, :duration_days, :phase]
    config.create.label = :create_deferral_type_label
    config.columns[:phase].clear_link
    config.columns[:phase].form_ui = :select
    config.create.columns = [:name, :description, :duration_semesters, :duration_months, :duration_days, :phase]
    config.update.columns = [:name, :description, :duration_semesters, :duration_months, :duration_days, :phase]
    config.show.columns = [:name, :description, :duration_semesters, :duration_months, :duration_days, :phase]

    config.actions.exclude :deleted_records
  end

end
