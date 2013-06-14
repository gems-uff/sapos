# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :role do
    sequence :name do |name|
      "Role_#{name}"
    end
    sequence :description do |name|
      "RoleDescription_#{name}"
    end

    factory :role_administrador do
      id Role::ROLE_ADMINISTRADOR
      name "Administrador"
      description "Descricao Administrador"
    end
  end
end
