# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

FactoryBot.define do
  factory :scholarship_type do
    sequence :name do |name|
      "ScholarshipType_#{name}"
    end
  end
end
