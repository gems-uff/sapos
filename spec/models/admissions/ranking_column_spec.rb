# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::RankingColumn, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:ranking_config).required(false) }
  it { should belong_to(:admission_report_config).required(false) }

  before(:all) do
    @destroy_later = []
    @form_field = FactoryBot.create(:form_field, name: "Coluna")
    @ranking_config = FactoryBot.create(:ranking_config)
  end
  after(:all) do
    @form_field.delete
    @ranking_config.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:ranking_column) do
    Admissions::RankingColumn.new(
      ranking_config: @ranking_config,
      name: "Coluna",
      order: Admissions::RankingColumn::ASC
    )
  end
  subject { ranking_column }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:order) }
    it { should validate_inclusion_of(:order).in_array(Admissions::RankingColumn::ORDERS) }
    describe "that_field_name_exists" do
      it "should be valid if field exists" do
        ranking_column.name = "Coluna"
        expect(ranking_column).to be_valid
      end
      it "should have error if field does not exist" do
        ranking_column.name = "C"
        expect(ranking_column).to have_error(:field_not_found).on(:base).with_parameters(field: "C")
        ranking_column.name = "Coluna"
      end
      it "should be valid if name is blank" do
        ranking_column.name = ""
        expect(ranking_column).not_to have_error(:field_not_found).on(:base).with_parameters(field: "")
      end
    end
    describe "that_it_either_has_ranking_config_or_admission_report_config" do
      it "should be valid if it has ranking_config" do
        ranking_column.ranking_config = @ranking_config
        ranking_column.admission_report_config = nil
        expect(ranking_column).to be_valid
      end
      it "should be valid if it has admission_report_config" do
        ranking_column.ranking_config = nil
        ranking_column.admission_report_config = FactoryBot.create(:admission_report_config)
        expect(ranking_column).to be_valid
      end
      it "should not be valid if it has neither ranking_config nor admission_report_config" do
        ranking_column.ranking_config = nil
        ranking_column.admission_report_config = nil
        expect(ranking_column).not_to be_valid
        expect(ranking_column).to have_error(:at_least_one_relationship).on :base
      end
      it "should not be valid if it has both ranking_config and admission_report_config" do
        ranking_column.ranking_config = @ranking_config
        @destroy_later << ranking_column.admission_report_config = FactoryBot.create(:admission_report_config)
        expect(ranking_column).not_to be_valid
        expect(ranking_column).to have_error(:at_least_one_relationship).on :base
      end
    end
  end
  # ToDo: after_initialize

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        ranking_column.name = "Coluna"
        ranking_column.order = Admissions::RankingColumn::ASC
        expect(ranking_column.to_label).to eq("Coluna #{Admissions::RankingColumn::ASC}")
      end
    end
    # ToDo: compare
    # ToDo: convert
  end
end
