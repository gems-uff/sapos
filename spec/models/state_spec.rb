# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe State, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:cities).dependent(:restrict_with_exception) }
  it { should have_many(:student_birth_states).class_name("Student").with_foreign_key("birth_state_id").dependent(:restrict_with_exception) }

  let(:country) { FactoryBot.build(:country) }
  let(:state) do
    State.new(
      country: country,
      name: "Rio de Janeiro",
      code: "RJ"
    )
  end
  subject { state }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:country).required(true) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:code) }
    it { should validate_presence_of(:code) }
  end
end
