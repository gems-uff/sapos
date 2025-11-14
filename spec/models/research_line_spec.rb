# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ResearchLine, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:course_research_lines).dependent(:destroy) }
  it { should have_many(:courses).through(:course_research_lines) }
  it { should have_many(:enrollments).dependent(:nullify) }
  it { should have_many(:professor_research_lines).dependent(:destroy) }
  it { should have_many(:professors).through(:professor_research_lines) }

  let(:research_area) { FactoryBot.build(:research_area) }
  let(:research_line) do
    ResearchLine.new(
      name: "Banco de Dados",
      research_area: research_area
    )
  end

  subject { research_line }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:name) }
    it { should belong_to(:research_area).required(true) }
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        research_line_name = "ResearchLine name"
        research_line.name = research_line_name
        expected = "#{research_line_name}"
        expect(research_line.to_label).to eql(expected)
      end
    end
  end
end
