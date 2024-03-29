# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    to_template { "sapos@mailinator.com" }
    subject_template { "test" }
    body_template { "test" }
    notification_offset { 0 }
    query_offset { 0 }
    frequency { Notification::SEMIANNUAL }
    title { "test" }
    query
  end
end
