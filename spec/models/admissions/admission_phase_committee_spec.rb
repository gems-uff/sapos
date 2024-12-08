# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionPhaseCommittee, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:admission_phase).required(true) }
  it { should belong_to(:admission_committee).required(true) }

  before(:all) do
    @destroy_later = []
    @admission_phase = FactoryBot.create(:admission_phase)
    @admission_committee = FactoryBot.create(:admission_committee)
  end
  after(:all) do
    @admission_phase.delete
    @admission_committee.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_phase_committee) do
    Admissions::AdmissionPhaseCommittee.new(
      admission_phase: @admission_phase,
      admission_committee: @admission_committee
    )
  end
  subject { admission_phase_committee }
  describe "Validations" do
    it { should be_valid }
  end
  # ToDo: test after_commit

  describe "Methods" do
    # ToDo: to_label
  end
end
