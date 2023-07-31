# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ScholarshipType, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:scholarships).dependent(:restrict_with_exception) }

  let(:name) { "Projeto" }
  let(:scholarship_type) { ScholarshipType.new(name: name) }
  subject { scholarship_type }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end
  describe "Methods" do
    context "to_label" do
      it "should return the scholarship type name" do
        expect(scholarship_type.name).to eq(name)
      end
    end
  end
end
