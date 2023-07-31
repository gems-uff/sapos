# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :query_param do
    query
    name { "_a" }
    default_value { "MyString" }
    value_type { "String" }
  end
end
