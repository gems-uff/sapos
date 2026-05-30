# frozen_string_literal: true

class ProgramLevelsController < ApplicationController
  authorize_resource

  active_scaffold :program_level do |config|
    config.create.columns = [:level, :ordinance, :start_date, :end_date]
    config.update.columns = [:level, :ordinance, :start_date, :end_date]
    config.show.columns = [:level, :ordinance, :start_date, :end_date]
    config.list.columns = [:level, :ordinance, :start_date, :end_date]

    config.actions.swap :search, :field_search
    config.columns.add :active
    config.field_search.columns = [:active]
    config.columns[:active].form_ui = :select

    config.actions.exclude :deleted_records
  end

end
