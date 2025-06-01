# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence :email do |email|
      "email#{email}@test.com"
    end
    sequence :name do |name|
      "User_#{name}"
    end
    password { "password" }

    trait :admin do
      after(:create) do |user|
        role = FactoryBot.create(:role_administrador)
        FactoryBot.create(:user_role, user: user, role: role)
      end
    end

    trait :professor do
      after(:create) do |user|
        role = Role.find_by(id: Role::ROLE_PROFESSOR) || FactoryBot.create(:role_professor)
        UserRole.where(user: user, role: role).first_or_create!
      end
    end

    trait :student do
      after(:create) do |user|
        role = FactoryBot.create(:role_aluno)
        FactoryBot.create(:user_role, user: user, role: role)
      end
    end

    trait :coordination do
      after(:create) do |user|
        role = FactoryBot.create(:role_coordenacao)
        FactoryBot.create(:user_role, user: user, role: role)
      end
    end

    trait :secretary do
      after(:create) do |user|
        role = FactoryBot.create(:role_secretaria)
        FactoryBot.create(:user_role, user: user, role: role)
      end
    end
  end
end
