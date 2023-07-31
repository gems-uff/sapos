# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :email_template do
    name { "" }
    to { "MyString" }
    subject { "MyString" }
    body { "MyText" }
    enabled { false }
  end
end
