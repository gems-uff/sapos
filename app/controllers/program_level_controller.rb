# frozen_string_literal: true

class ProgramLevelController < ApplicationController
  authorize_resource
  active_scaffold :program_level do |config|
    config.create.columns = [:level]
    config.update.columns = [:level]
    config.show.columns = [:level, :start_date, :end_date]
    config.list.columns = [:level, :start_date]
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

    def do_create
      super
      # AFTER CREATE
      # Coloca a data de início com a mesma do created_at

      pl = ProgramLevel.last
      pl.update!(start_date: pl.created_at)
    end

    def conditions_for_collection
      ["end_date is null"]
    end
end
