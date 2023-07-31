# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProfessorResearchArea, type: :model do
  let(:professor) { FactoryBot.build(:professor) }
  let(:research_area) { FactoryBot.build(:research_area) }
  let(:professor_research_area) do
    ProfessorResearchArea.new(
      professor: professor,
      research_area: research_area
    )
  end
  subject { professor_research_area }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:professor).required(true) }
    it { should belong_to(:research_area).required(true) }
    it { should validate_uniqueness_of(:professor).scoped_to(:research_area_id).with_message(:unique_pair) }
  end
end
