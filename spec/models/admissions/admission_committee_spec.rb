# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionCommittee, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:members).dependent(:destroy) }
  it { should have_many(:users).through(:members) }
  it { should have_many(:admission_phase_committees).dependent(:destroy) }
  it { should have_many(:admission_phases).through(:admission_phase_committees) }

  it { should belong_to(:form_condition).required(false) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_committee) do
    Admissions::AdmissionCommittee.new(
      name: "Comitê",
    )
  end
  subject { admission_committee }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
  end
  # ToDo: test after_commit

  describe "Methods" do
    # ToDo: to_label
    # ToDo: initialize_dup
  end
end
