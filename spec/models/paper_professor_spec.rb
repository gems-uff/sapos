# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe PaperProfessor, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:paper).required(true) }
  it { should belong_to(:professor).required(true) }

  let(:professor) { FactoryBot.build(:professor) }
  let(:paper) { FactoryBot.build(:paper) }
  let(:paper_professor) do
    PaperProfessor.new(
      paper: paper,
      professor: professor
    )
  end
  subject { paper_professor }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:paper) }
    it { should validate_presence_of(:professor) }
  end
  describe "Methods" do
    describe "to_label" do
      it "should return 'professor - paper'" do
        professor.name = "Bia"
        paper.owner.name = "Ana"
        paper.reference = "Ana. Artigo. 2024"
        expect(paper_professor.to_label).to eq("Bia - [Ana] Ana. Artigo. 2024")
      end
    end
  end
end
