# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :user do
    sequence :email do |email|
      "email#{email}@test.com"
    end
    sequence :name do |name|
      "User_#{name}"
    end
    password { "password" }
    role_id { Role::ROLE_ADMINISTRADOR }
  end
end
