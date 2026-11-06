# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Filtro "Vigente" das telas de período: id IN/NOT IN sobre o
# on_date(Date.current) do modelo, que já codifica o término de cada um.
# Precedente: EnrollmentHoldsController#condition_for_active_column.
module CurrentPeriodSearchConcern
  extend ActiveSupport::Concern

  class_methods do
    def add_current_period_search_column(config)
      config.columns.add :active
      config.list.columns.exclude :active
      config.show.columns.exclude :active
      config.create.columns.exclude :active
      config.update.columns.exclude :active
      config.columns[:active].search_sql = ""
      config.columns[:active].search_ui = :select
      config.columns[:active].options = {
        options: [
          [I18n.t("active_scaffold.true"), "1"],
          [I18n.t("active_scaffold.false"), "0"]
        ],
        include_blank: true,
        default: nil,
      }
    end

    # Em branco tem de devolver nil: qualquer outro valor conta como filtro.
    def condition_for_active_column(column, value, like_pattern)
      return nil if value.blank?
      model = active_scaffold_config.model
      ids = model.on_date(Date.current).select(:id).to_sql
      case value
      when "1" then "#{model.table_name}.id IN (#{ids})"
      when "0" then "#{model.table_name}.id NOT IN (#{ids})"
      end
    end
  end
end
