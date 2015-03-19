# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

FactoryGirl.define do
  factory :query_param do
    query nil
    default_value "MyString"
    value_type "MyString"
  end
end
