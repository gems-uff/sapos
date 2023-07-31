# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhaseCompletion, type: :model do
  let(:phase) { FactoryBot.build(:phase) }
  let(:level) { FactoryBot.build(:level) }
  let(:enrollment) { FactoryBot.build(:enrollment, level: level) }

  let(:phase_completion) do
    PhaseCompletion.new(
      phase: phase,
      enrollment: enrollment
    )
  end
  subject { phase_completion }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:phase).required(true) }
    it { should belong_to(:enrollment).required(true) }
    it { should validate_uniqueness_of(:phase).scoped_to(:enrollment_id) }
  end
end
