# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Paper, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:owner).required(true) }
  it { should have_many(:paper_professors).dependent(:destroy) }
  it { should have_many(:paper_students).dependent(:destroy) }
  it { should have_many(:professors).through(:paper_professors) }
  it { should have_many(:students).through(:paper_students) }

  let(:professor) { FactoryBot.build(:professor) }
  let(:user) { FactoryBot.build(:user, professor: professor) }
  let(:paper) do
    Paper.new(
      period: "2021 - 2024",
      reference: "Autor. Artigo. Ano",
      kind: Paper::JOURNAL,
      doi_issn_event: "10000000",
      owner: professor,
      reason_international_list: true,
      reason_justify: "Internacional",
      impact_factor: "1",
      order: 1
    )
  end
  subject { paper }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:reference) }
    it { should validate_inclusion_of(:kind).in_array(Paper::KINDS) }
    it { should validate_presence_of(:kind) }
    it { should validate_inclusion_of(:order).in_array(Paper::ORDERS) }
    it { should validate_uniqueness_of(:order).scoped_to([:period, :owner_id]).with_message(:order_uniqueness) }
    it { should validate_presence_of(:order) }
    it { should validate_presence_of(:doi_issn_event) }
    it { should validate_presence_of(:reason_justify) }
    it { should validate_presence_of(:impact_factor) }
    # ToDo: professor cannot edit other papers

  end
  describe "Methods" do
    describe "to_label" do
      it "should return '[professor] reference'" do
        paper.owner.name = "Ana"
        paper.reference = "Ana. Artigo. 2024"
        expect(paper.to_label).to eq("[Ana] Ana. Artigo. 2024")
      end
    end
  end
end
