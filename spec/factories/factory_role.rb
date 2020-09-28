# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :role do
    sequence :name do |name|
      "Role_#{name}"
    end
    sequence :description do |name|
      "RoleDescription_#{name}"
    end

    factory :role_administrador do
      id { Role::ROLE_ADMINISTRADOR }
      name { "Administrador" }
      description { "Descricao Administrador" }
      initialize_with {Role.where(id: id).first_or_create(name: name, description: description)}
    end
  end
end
