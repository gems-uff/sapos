# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :dismissal_reason do
    thesis_judgement { DismissalReason::APPROVED }
    sequence :name do |name|
      "DismissalReason_#{name}"
    end
  end
end
