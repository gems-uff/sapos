# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Grant, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:professor).required(true) }

  let(:professor) { FactoryBot.build(:professor) }
  let(:user) { FactoryBot.build(:user, professor: professor) }
  let(:grant) do
    Grant.new(
      title: "Title",
      start_year: 2024,
      kind: Grant::PUBLIC,
      funder: "CNPq",
      amount: 100000,
      professor: professor
    )
  end
  subject { grant }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:start_year) }
    it { should validate_inclusion_of(:kind).in_array(Grant::KINDS) }
    it { should validate_presence_of(:funder) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:professor) }
    it { should validate_numericality_of(:amount) }
    # ToDo: professor cannot edit other grants
    describe "end_year" do
      context "should be valid when" do
        it "is empty" do
          grant.end_year = nil
          expect(grant).to have(0).errors_on :end_year
        end
        it "is grater than start_year" do
          grant.end_year = grant.start_year + 1
          expect(grant).to have(0).errors_on :end_year
        end
      end
      context "should have start_greater_than_end error when" do
        it "start_year is greater than end_year" do
          grant.end_year = grant.start_year - 1
          expect(grant).to have_error(:start_greater_than_end).on :end_year
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return '[year] title'" do
        grant.start_year = 2024
        grant.title = "Projeto"
        expect(grant.to_label).to eq("[2024] Projeto")
      end
    end
  end
end
