# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Database-neutral uniqueness coverage: exact duplicates, scope isolation and
# blank exemption. None of it depends on the collation, so it is green on both
# SQLite (development) and MariaDB (CI and production). The case- and accent-
# insensitive behavior that only MariaDB can express lives in
# spec/models/uniqueness_collation_spec.rb.
#
# The declarations live in the models (validates ..., uniqueness: ...). Listing
# them here in one place keeps the collation boundary explicit: whatever is here
# runs everywhere; whatever needs the production collation is in the sibling
# file.
RSpec.describe "Uniqueness (database-neutral)", type: :model do
  before(:all) { @role_professor = FactoryBot.create(:role_professor) }
  after(:all) { @role_professor.delete }

  # Single unique attribute, no scope, no blank exemption.
  [
    [:country, :name],
    [:course_type, :name],
    [:course, :code],
    [:dismissal_reason, :name],
    [:enrollment_status, :name],
    [:enrollment, :enrollment_number],
    [:institution, :name],
    [:level, :name],
    [:phase, :name],
    [:research_area, :name],
    [:research_area, :code],
    [:research_line, :name],
    [:scholarship_type, :name],
    [:scholarship, :scholarship_number],
    [:sponsor, :name],
    [:state, :name],
    [:state, :code],
    [:student, :cpf],
    [:professor, :cpf],
  ].each do |factory, attribute|
    describe "#{factory}##{attribute}" do
      include_examples "a unique attribute", factory, attribute
    end
  end

  # Unique but exempt when blank (allow_blank / allow_nil). A value is supplied
  # because the factory leaves the attribute blank.
  {
    [:email_template, :name] => "Template",
    [:professor, :email] => "professor@ic.uff.br",
    [:professor, :enrollment_number] => "P1",
  }.each do |(factory, attribute), value|
    describe "#{factory}##{attribute}" do
      include_examples "a unique attribute", factory, attribute, value
      include_examples "an optional unique attribute", factory, attribute
    end
  end

  # Unique within a scope.
  describe "admissions/form_field#sync" do
    include_examples "a unique attribute scoped to",
      :form_field, :sync, :form_template_id, Admissions::FormField::SYNC_NAME
    include_examples "an optional unique attribute", :form_field, :sync
  end

  describe "admissions/admission_application#email" do
    include_examples "a unique attribute scoped to",
      :admission_application, :email, :admission_process_id, "dup@email.com"
  end
end
