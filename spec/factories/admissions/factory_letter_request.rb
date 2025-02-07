# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :letter_request, class: Admissions::LetterRequest, aliases: [
    "admissions/letter_request"
  ] do
    name { "Ana" }
    email { "ana@ic.uff.br" }
    admission_application { create(:admission_application, :in_process_with_letters) }
    filled_form
  end
end
