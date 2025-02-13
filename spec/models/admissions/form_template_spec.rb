# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::FormTemplate, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:fields).dependent(:destroy) }
  it { should have_many(:admission_process_forms).dependent(:restrict_with_exception) }
  it { should have_many(:admission_process_letters).dependent(:restrict_with_exception) }
  it { should have_many(:phase_member_forms).dependent(:restrict_with_exception) }
  it { should have_many(:phase_shared_forms).dependent(:restrict_with_exception) }
  it { should have_many(:phase_consolidation_forms).dependent(:restrict_with_exception) }
  it { should have_one(:ranking_config).dependent(:destroy) }
  it { should have_many(:admission_report_configs).dependent(:restrict_with_exception) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:form_template) do
    Admissions::FormTemplate.new(
      name: "Form",
      template_type: Admissions::FormTemplate::ADMISSION_FORM,
    )
  end
  subject { form_template }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:template_type) }
    it { should validate_inclusion_of(:template_type).in_array(Admissions::FormTemplate::TEMPLATE_TYPES) }
  end
  describe "Duplication" do
    it "should duplicate fields" do
      field = form_template.fields.build(
        name: "str",
        field_type: Admissions::FormField::STRING
      )
      expect(form_template.fields.size).to eql(1)
      duplicate = form_template.dup
      expect(duplicate.fields[0]).not_to be(field)
      field.destroy
    end
  end
  describe "Methods" do
    describe "has_file_fields?" do
      it "should return false if it doesn't have any fields" do
        expect(form_template.has_file_fields?).to eql(false)
        expect(form_template.fields.size).to eql(0)
      end
      it "should return false if it doesn't have any file fields" do
        field = form_template.fields.build(
          name: "str",
          field_type: Admissions::FormField::STRING
        )
        expect(form_template.has_file_fields?).to eql(false)
        expect(form_template.fields.size).to eql(1)
        field.destroy
      end
      it "should return true if it hasfile fields" do
        field = form_template.fields.build(
          name: "file",
          field_type: Admissions::FormField::FILE
        )
        expect(form_template.has_file_fields?).to eql(true)
        expect(form_template.fields.size).to eql(1)
        field.destroy
      end
    end
  end
end
