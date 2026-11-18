# frozen_string_literal: true

class ProgramLevelsController < ApplicationController
  include CurrentPeriodSearchConcern

  authorize_resource

  active_scaffold :program_level do |config|
    config.create.columns = [:level, :ordinance, :start_date, :end_date]
    config.update.columns = [:level, :ordinance, :start_date, :end_date]
    config.show.columns = [:level, :ordinance, :start_date, :end_date]
    config.list.columns = [:level, :ordinance, :start_date, :end_date]

    config.actions.swap :search, :field_search
    config.field_search.columns = [:active]
    add_current_period_search_column(config)

    config.actions.exclude :deleted_records
  end
end
