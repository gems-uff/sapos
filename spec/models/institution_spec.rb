# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Institution, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:majors).dependent(:restrict_with_exception) }
  it { should have_many(:affiliations) }
  it { should have_many(:professors).through(:affiliations) }

  let(:institution) { Institution.new(name: "instituicao") }
  subject { institution }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:name) }
  end

  describe "Methods" do
    describe "search_name" do
      before(:all) do
        @inst1 = FactoryBot.create(:institution, name: "Universidade Federal Fluminense", code: "UFF")
        @inst2 = FactoryBot.create(:institution, name: "Pontifícia Universidade Católica", code: "PUC")
      end

      after(:all) do
        @inst1.delete
        @inst2.delete
      end

      context "exact match" do
        it "finds by exact name" do
          result = Institution.search_name(institution: "Universidade Federal Fluminense")
          expect(result).to include(@inst1)
          expect(result).not_to include(@inst2)
        end

        it "finds by exact code" do
          result = Institution.search_name(institution: "UFF")
          expect(result).to include(@inst1)
          expect(result).not_to include(@inst2)
        end

        it "returns empty collection when no match" do
          result = Institution.search_name(institution: "INEXISTENTE")
          expect(result).to be_empty
        end
      end

      context "substring match" do
        it "finds institutions whose name contains the term" do
          result = Institution.search_name(institution: "Universidade", substring: true)
          expect(result).to include(@inst1, @inst2)
        end

        it "finds by partial code" do
          result = Institution.search_name(institution: "UF", substring: true)
          expect(result).to include(@inst1)
          expect(result).not_to include(@inst2)
        end
      end
    end
  end
end
