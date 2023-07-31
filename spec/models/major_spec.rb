# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Major, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:student_majors).dependent(:destroy) }
  it { should have_many(:students).through(:student_majors) }

  let(:level) { FactoryBot.build(:level) }
  let(:institution) { FactoryBot.build(:institution) }
  let(:major) do
    Major.new(
      name: "computacao",
      level: level,
      institution: institution
    )
  end
  subject { major }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:level).required(true) }
    it { should belong_to(:institution).required(true) }
    it { should validate_presence_of(:name) }
  end

  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        level_name = "Major Level"
        major_name = "Major Name"
        institution_name = "Major Institution"
        major.level = Level.new(name: level_name)
        major.name = major_name
        major.institution = Institution.new(name: institution_name)
        expected = "#{major_name} - #{institution_name} - (#{level_name})"
        expect(major.to_label).to eql(expected)
      end
    end
  end
end
