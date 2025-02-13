# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionReportColumn, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:admission_report_group).required(true) }

  before(:all) do
    @destroy_later = []
    @admission_report_group = FactoryBot.create(:admission_report_group)
    @admissions_form_field = FactoryBot.create(:form_field, name: "coluna")
  end
  after(:all) do
    @admission_report_group.delete
    @admissions_form_field.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_report_column) do
    Admissions::AdmissionReportColumn.new(
      admission_report_group: @admission_report_group,
      name: "coluna"
    )
  end
  subject { admission_report_column }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    describe "that_field_name_exists" do
      it "should be valid if field exists" do
        admission_report_column.name = "coluna"
        expect(admission_report_column).to be_valid
      end
      it "should have error if field does not exist" do
        admission_report_column.name = "c"
        expect(admission_report_column).to have_error(:field_not_found).on(:base).with_parameters(field: "c")
        admission_report_column.name = "coluna"
      end
    end
  end

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        admission_report_column.name = "Coluna"
        expect(admission_report_column.to_label).to eq("Coluna")
      end
    end
  end
end
