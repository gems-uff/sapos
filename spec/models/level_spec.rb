# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Level, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:advisement_authorizations).dependent(:destroy) }
  it { should have_many(:enrollments).dependent(:restrict_with_exception) }
  it { should have_many(:majors).dependent(:restrict_with_exception) }
  it { should have_many(:phase_durations).dependent(:restrict_with_exception) }
  it { should have_many(:scholarships).dependent(:restrict_with_exception) }

  let(:level) do
    Level.new(
      name: "mestrado",
      default_duration: 24
    )
  end
  subject { level }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:default_duration) }
  end
end
