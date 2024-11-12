# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"


RSpec.describe Admissions::FormField, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:filled_fields).dependent(:restrict_with_exception) }
  it { should have_one(:ranking_config_as_position).dependent(:destroy) }
  it { should have_one(:ranking_config_as_machine).dependent(:destroy) }

  before(:all) do
    @destroy_later = []
    @form_template = FactoryBot.create(:form_template)
  end
  after(:all) do
    @form_template.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:form_field) do
    Admissions::FormField.new(
      name: "Campo",
      form_template: @form_template,
      field_type: Admissions::FormField::STRING
    )
  end
  subject { form_field }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:form_template) }
    it do
      should validate_uniqueness_of(:sync).scoped_to(:form_template_id).allow_nil
    end
    it { should validate_inclusion_of(:field_type).in_array(Admissions::FormField::FIELD_TYPES) }
    # ToDo: test sync
    describe "configuration" do
      context "should be valid when" do
        it "field_type does not require extra configurations" do
          form_field.field_type = Admissions::FormField::STRING
          expect(form_field).to have(0).errors_on :base
        end
      end
      context "for select field_type" do
        context "should be valid when" do
          it "configuration has values" do
            form_field.field_type = Admissions::FormField::SELECT
            form_field.configuration = JSON.dump({ values: ["a", "b"] })
            expect(form_field).to be_valid
            expect(form_field).to have(0).errors_on :base
          end
          it "configurarion has valid sql" do
            form_field.field_type = Admissions::FormField::SELECT
            form_field.configuration = JSON.dump({ values_use_sql: true, values_sql: "select * from enrollments" })
            expect(form_field).to be_valid
            expect(form_field).to have(0).errors_on :base
          end
        end
        context "should have error when" do
          it "configuration does not have sql nor values" do
            form_field.field_type = Admissions::FormField::SELECT
            form_field.configuration = nil
            expect(form_field).not_to be_valid
            expect(form_field).to have_error(:values_present_error).on :base
          end
          it "configuration has blank value" do
            form_field.field_type = Admissions::FormField::SELECT
            form_field.configuration = JSON.dump({ values: [""] })
            expect(form_field).not_to be_valid
            expect(form_field).to have_error(:values_blank_error).on :base
          end
        end
        it "configuration has blank sql" do
          form_field.field_type = Admissions::FormField::SELECT
          form_field.configuration = JSON.dump({ values_use_sql: true, values_sql: "" })
          expect(form_field).not_to be_valid
          expect(form_field).to have_error(:values_sql_present_error).on :base
        end
        it "configuration has invalid sql" do
          form_field.field_type = Admissions::FormField::SELECT
          form_field.configuration = JSON.dump({ values_use_sql: true, values_sql: "select * from invalid" })
          expect(form_field).not_to be_valid
          expect(form_field).to have(1).errors_on :base
        end
      end
    end
  end

  describe "Methods" do
  end
end
