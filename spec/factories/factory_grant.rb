# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :grant do
    title { "Projeto" }
    start_year { 2024 }
    kind { Grant::PUBLIC }
    funder { "CNPq" }
    amount { 100000 }
    professor
  end
end
