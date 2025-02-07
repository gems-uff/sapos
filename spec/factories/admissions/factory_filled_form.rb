# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :filled_form, class: Admissions::FilledForm, aliases: [
    "admissions/filled_form"
  ] do
    form_template
    is_filled { false }
  end
end
