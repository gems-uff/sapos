# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

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
      initialize_with { Role.where(id: id).first_or_create(name: name, description: description) }
    end

    factory :role_coordenacao do
      id { Role::ROLE_COORDENACAO }
      name { "Coordenacao" }
      description { "Descricao Coordenacao" }
      initialize_with { Role.where(id: id).first_or_create(name: name, description: description) }
    end

    factory :role_secretaria do
      id { Role::ROLE_SECRETARIA }
      name { "Secretaria" }
      description { "Descricao Secretaria" }
      initialize_with { Role.where(id: id).first_or_create(name: name, description: description) }
    end

    factory :role_professor do
      id { Role::ROLE_PROFESSOR }
      name { "Professor" }
      description { "Descricao Professor" }
      initialize_with { Role.where(id: id).first_or_create(name: name, description: description) }
    end

    factory :role_aluno do
      id { Role::ROLE_ALUNO }
      name { "Aluno" }
      description { "Descricao Aluno" }
      initialize_with { Role.where(id: id).first_or_create(name: name, description: description) }
    end
  end
end
