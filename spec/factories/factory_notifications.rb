# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    to_template "sapos@mailinator.com"
    subject_template "test"
    body_template "test"
    notification_offset 0
    query_offset 0
    frequency I18n.translate("activerecord.attributes.notification.frequencies.daily")
    title "test"
    query
  end
end
