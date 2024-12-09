# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :ranking_column, class: Admissions::RankingColumn, aliases: [
    "admissions/ranking_column"
  ] do
    name { "Coluna" }
    order { Admissions::RankingColumn::ASC }

    after(:build) do |column, factory|
      if !Admissions::FormField.field_name_exists?(column.name)
        FactoryBot.create(:form_field, name: column.name)
      end
      if column.ranking_config.blank? && column.admission_report_config.blank?
        column.ranking_config = FactoryBot.build(:ranking_config, default_column: nil)
        column.ranking_config.ranking_columns << column
      end
    end
  end
end
