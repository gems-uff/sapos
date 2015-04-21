# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :student do
    sequence :cpf do |cpf|
      "#{cpf}"
    end
    sequence :name do |name|
      "Student_#{name}"
    end
  end
end
