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

      old_record = ProgramLevel.find_by_id(params[:id])

      super

      if old_record.level.to_s != @record.level
        new_record = old_record.dup
        new_record.end_date = @record.start_date
        new_record.save
      end
      flash[:info] = "Atualizado com sucesso! Atualize a página para ter todos os conceitos CAPES."
    end
end
