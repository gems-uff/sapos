# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe PaperStudent, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:paper).required(true) }
  it { should belong_to(:student).required(true) }

  let(:student) { FactoryBot.build(:student) }
  let(:paper) { FactoryBot.build(:paper) }
  let(:paper_student) do
    PaperStudent.new(
      paper: paper,
      student: student
    )
  end
  subject { paper_student }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:paper) }
    it { should validate_presence_of(:student) }
  end
  describe "Methods" do
    describe "to_label" do
      it "should return 'student - paper'" do
        student.name = "Bia"
        paper.owner.name = "Ana"
        paper.reference = "Ana. Artigo. 2024"
        expect(paper_student.to_label).to eq("Bia - [Ana] Ana. Artigo. 2024")
      end
    end
  end
end
