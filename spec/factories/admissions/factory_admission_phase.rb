# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_phase, class: Admissions::AdmissionPhase, aliases: [
    "admissions/admission_phase"
  ] do
    # association :approval_condition, factory: form_condition
    # association :keep_in_phase_condition, factory: form_condition
    # association :consolidation_form, factory: form_template
    # association :candidate_form, factory: form_template
    name { "Fase 1" }
    can_edit_candidate { false }
    candidate_can_see_member { false }
    candidate_can_see_shared { false }
    candidate_can_see_consolidation { false }

    trait :with_member_form do
      member_form { create(:form_template) }
    end
    trait :with_shared_form do
      shared_form { create(:form_template) }
    end
  end
end
