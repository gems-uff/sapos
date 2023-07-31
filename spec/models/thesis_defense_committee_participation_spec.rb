# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ThesisDefenseCommitteeParticipation, type: :model do
  let(:professor) { FactoryBot.build(:professor) }
  let(:enrollment) { FactoryBot.build(:enrollment) }
  let(:thesis_defense_committee_participation) do
    ThesisDefenseCommitteeParticipation.new(
      professor: professor,
      enrollment: enrollment
    )
  end
  subject { thesis_defense_committee_participation }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:professor).required(true) }
    it { should belong_to(:enrollment).required(true) }
    it { should validate_uniqueness_of(:professor).scoped_to(:enrollment_id).with_message(:thesis_defense_committee_participation_professor_uniqueness) }
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        enrollment_number = "123"
        professor_name = "professor"
        thesis_defense_committee_participation.enrollment = Enrollment.new(enrollment_number: enrollment_number)
        thesis_defense_committee_participation.professor = Professor.new(name: professor_name)
        expect(thesis_defense_committee_participation.to_label).to eql("#{enrollment_number} - #{professor_name}")
      end
    end
  end
end
