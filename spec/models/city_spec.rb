# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe City, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:students).dependent(:restrict_with_exception) }
  it { should have_many(:student_birth_cities).class_name("Student").with_foreign_key(:birth_city_id).dependent(:restrict_with_exception) }
  it { should have_many(:professors).dependent(:restrict_with_exception) }

  let(:state) { FactoryBot.build(:state) }
  let(:city) do
    City.new(
      name: "niteroi",
      state: state
    )
  end
  subject { city }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:state).required(true) }
    it { should validate_presence_of(:name) }
  end
end
