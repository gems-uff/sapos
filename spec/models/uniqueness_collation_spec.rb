# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Case- and accent-insensitive uniqueness — the production behavior that comes
# from the MariaDB collation utf8mb4_unicode_ci. SQLite compares strings
# byte-for-byte and cannot reproduce it, so this file runs only under MySQL/
# MariaDB (skip the whole file otherwise). The database-neutral half lives in
# spec/models/uniqueness_spec.rb.
#
# Run it with the suite-mariadb skill or in CI (which runs on MariaDB).
if ActiveRecord::Base.connection.adapter_name == "Mysql2"
  RSpec.describe "Uniqueness under the production collation", type: :model do
    before(:all) { @role_professor = FactoryBot.create(:role_professor) }
    after(:all) { @role_professor.delete }

    # Case-insensitive: "Jose" and "JOSE" collide. Every unique string column
    # inherits this from the collation. sync is excluded on purpose: its value
    # is constrained to a fixed, case-sensitive set (inclusion), so a differently
    # cased duplicate can never be created to begin with.
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
        include_examples "a case-insensitive attribute", factory, attribute
      end
    end

    {
      [:email_template, :name] => "Template",
      [:professor, :email] => "professor@ic.uff.br",
      [:professor, :enrollment_number] => "P1",
    }.each do |(factory, attribute), value|
      describe "#{factory}##{attribute}" do
        include_examples "a case-insensitive attribute", factory, attribute, value
      end
    end

    describe "admissions/admission_application#email" do
      include_examples "a case-insensitive attribute",
        :admission_application, :email, "dup@email.com", :admission_process_id
    end

    # Accent-insensitive: "José" and "Jose" collide. Only meaningful for the
    # free-text name fields; codes, numbers, cpf and e-mail carry no accents.
    [
      :country, :course_type, :dismissal_reason, :enrollment_status,
      :institution, :level, :phase, :research_area, :research_line,
      :scholarship_type, :sponsor, :state,
    ].each do |factory|
      describe "#{factory}#name" do
        include_examples "an accent-insensitive attribute", factory, :name, "José", "Jose"
      end
    end
  end
end
