# frozen_string_literal: true

class ProgramLevelsController < ApplicationController
  authorize_resource
  active_scaffold :program_level do |config|
    config.create.columns = [:level, :start_date, :end_date]
    config.update.columns = [:level, :start_date, :end_date]
    config.show.columns = [:level, :start_date, :end_date]
    config.list.columns = [:level, :start_date, :end_date]

    config.actions.swap :search, :field_search
    config.columns.add :active
    config.field_search.columns = [:active]

    config.actions.exclude :deleted_records
  end

  protected
    def do_update
      # BEFORE UPDATE
      # cria o histórico

      pl = ProgramLevel.last
      unless pl.nil?
        ProgramLevel.create!(
          level: pl.level,
          start_date: pl.start_date,
          end_date: Time.now
        )
      end

      super
      # AFTER UPDATE
      # atualiza a data de início

      pl = ProgramLevel.last
      pl.update!(start_date: pl.updated_at)
    end
end
