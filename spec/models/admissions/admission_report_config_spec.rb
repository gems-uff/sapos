# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionReportConfig, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:groups).dependent(:destroy) }
  it { should have_many(:ranking_columns).dependent(:destroy) }
  it { should belong_to(:form_template).required(false) }
  it { should belong_to(:form_condition).required(false) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_report_config) do
    Admissions::AdmissionReportConfig.new(
      name: "Configuração de Relatório",
      group_column_tabular: Admissions::AdmissionReportConfig::COLUMN
    )
  end
  subject { admission_report_config }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:group_column_tabular) }
    it { should validate_inclusion_of(:group_column_tabular).in_array(Admissions::AdmissionReportConfig::GROUP_COLUMNS) }
  end

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        admission_report_config.name = "Configuração de Relatório"
        expect(admission_report_config.to_label).to eq("Configuração de Relatório")
      end
    end
    # ToDo: init_default
    # ToDo: init_simple
    # ToDo: prepare_table
    # ToDo: prepare_row
    # ToDo: prepare_excel_row
    # ToDo: prepare_html_row
    # ToDo: group_column
  end
end
