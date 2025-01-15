# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :ranking_config, class: Admissions::RankingConfig, aliases: [
    "admissions/ranking_config"
  ] do
    transient do
      default_column { "Coluna" }
      default_machine { create(:ranking_machine) }
    end
    name { "Configuração de Ranking" }
    behavior_on_invalid_condition { Admissions::RankingConfig::IGNORE_CONDITION }
    behavior_on_invalid_ranking { Admissions::RankingConfig::IGNORE_RANKING }

    after(:build) do |config, factory|
      if factory.default_column.present?
        if !Admissions::FormField.field_name_exists?(factory.default_column)
          FactoryBot.create(:form_field, name: factory.default_column)
        end
        config.ranking_columns.build(name: factory.default_column, order: Admissions::RankingColumn::ASC)
      end
      if factory.default_machine.present?
        config.ranking_processes.build(ranking_machine: factory.default_machine)
      end
    end
  end
end
