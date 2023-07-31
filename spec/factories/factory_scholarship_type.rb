# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :scholarship_type do
    sequence :name do |name|
      "ScholarshipType_#{name}"
    end
  end
end
