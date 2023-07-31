# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Country, type: :model  do
  it { should be_able_to_be_destroyed }
  it { should have_many(:state).dependent(:restrict_with_exception) }
  it { should have_many(:student_birth_countries).class_name("Student").dependent(:restrict_with_exception) }

  let(:country) { Country.new(name: "Brasil") }
  subject { country }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:name) }
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        name = "BR"
        country.name = name
        expect(country.to_label).to eql(name)
      end
    end
  end
end
