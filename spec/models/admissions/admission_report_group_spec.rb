# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionReportGroup, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:columns).dependent(:destroy) }
  it { should belong_to(:admission_report_config).required(true) }

  before(:all) do
    @destroy_later = []
    @admission_report_config = FactoryBot.create(:admission_report_config)
  end
  after(:all) do
    @admission_report_config.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_report_group) do
    Admissions::AdmissionReportGroup.new(
      admission_report_config: @admission_report_config,
      mode: Admissions::AdmissionReportGroup::MAIN,
      pdf_format: Admissions::AdmissionReportGroup::LIST,
      operation: Admissions::AdmissionReportGroup::INCLUDE
    )
  end
  subject { admission_report_group }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:mode) }
    it { should validate_inclusion_of(:mode).in_array(Admissions::AdmissionReportGroup::MODES) }
    it { should validate_presence_of(:pdf_format) }
    it { should validate_inclusion_of(:pdf_format).in_array(Admissions::AdmissionReportGroup::PDF_FORMATS) }
    it { should validate_presence_of(:operation) }
    it { should validate_inclusion_of(:operation).in_array(Admissions::AdmissionReportGroup::OPERATIONS) }
  end

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        admission_report_group.mode = Admissions::AdmissionReportGroup::MAIN
        admission_report_group.operation = Admissions::AdmissionReportGroup::INCLUDE
        expect(admission_report_group.to_label).to eq("#{Admissions::AdmissionReportGroup::MAIN} #{Admissions::AdmissionReportGroup::INCLUDE}")
      end
    end
    # ToDo: tabular_config
  end
end
