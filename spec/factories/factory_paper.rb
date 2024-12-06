# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :paper do
    period { "2021 - 2024" }
    reference { "Autor. Artigo. Ano"}
    kind { "Periódico" }
    doi_issn_event { "10000000" }
    owner { create(:professor) }
    reason_international_list { true }
    reason_justify { "Internacional" }
    impact_factor { "1" }
    order { 1 }
  end
end
