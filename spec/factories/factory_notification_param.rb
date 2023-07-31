# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :notification_param do
    notification
    query_param
    after(:build) do |obj|
      obj.query_param.query = obj.notification.query
    end
  end
end
