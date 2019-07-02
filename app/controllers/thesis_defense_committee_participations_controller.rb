# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ThesisDefenseCommitteeParticipationsController < ApplicationController
  authorize_resource

  active_scaffold :"thesis_defense_committee_participation" do |config|
  	columns = [:enrollment, :professor]
    config.create.label = :create_thesis_defense_committee_participation_label
    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns
    config.actions.swap :search, :field_search

    config.field_search.columns = [
      :professor
    ]

    config.columns[:enrollment].form_ui = :record_select
    config.columns[:professor].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
  record_select
end
