# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::FormCondition, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:parent).required(false) }
  it { should have_many(:form_conditions).dependent(:destroy) }
  it { should have_many(:admission_phases_as_approval).dependent(:nullify) }
  it { should have_many(:admission_committees).dependent(:nullify) }
  it { should have_many(:admission_report_configs).dependent(:nullify) }
  it { should have_many(:ranking_configs).dependent(:nullify) }

  before(:all) do
    @destroy_later = []
    @field_a = FactoryBot.create(:form_field, name: "a")
    @field_b = FactoryBot.create(:form_field, name: "b")
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @field_a.destroy
    @field_b.destroy
  end
  let(:form_condition) do
    Admissions::FormCondition.new(
      mode: Admissions::FormCondition::NONE,
      field: "a",
      condition: "=",
      value: "1"
    )
  end
  subject { form_condition }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:mode) }
    describe "validate conditions" do
      before(:each) do
        form_condition.mode = Admissions::FormCondition::CONDITION
      end
      it { should validate_presence_of(:field) }
      describe "that_field_name_exists" do
        it "should be valid if field exists" do
          form_condition.field = "a"
          expect(form_condition).to be_valid
        end
        it "should have error if field does not exist" do
          form_condition.field = "c"
          expect(form_condition).to have_error(:field_not_found).on(:base).with_parameters(field: "c")
          form_condition.field = "a"
        end
      end
    end
    describe "validate other modes" do
      it "should be valid if field is blank" do
        form_condition.mode = Admissions::FormCondition::NONE
        form_condition.field = ""
        expect(form_condition).to be_valid
      end
    end
  end
  describe "Duplication" do
    it "should duplicate sub form_conditions" do
      other = form_condition.form_conditions.build(
        mode: Admissions::FormCondition::NONE,
        field: "b",
        condition: "=",
        value: "1"
      )
      expect(form_condition.form_conditions.size).to eql(1)
      duplicate = form_condition.dup
      expect(duplicate.form_conditions[0]).not_to be(other)
      other.destroy
    end
  end
  describe "Methods" do
    # ToDo: test recursive_simple_validation
    # ToDo: test update_pendencies
    # ToDo: test to_label
    # ToDo: test compare
    # ToDo: test check_truth
    # ToDo: test new_from_hash
    # ToDo: test to_hash
    # ToDo: test widget
  end
end
