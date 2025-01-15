# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionPhase, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:admission_phase_committees).dependent(:destroy) }
  it { should have_many(:admission_committees).through(:admission_phase_committees) }
  it { should have_many(:admission_phase_results).dependent(:destroy) }
  it { should have_many(:admission_phase_evaluations).dependent(:destroy) }
  it { should have_many(:admission_process_phases).dependent(:destroy) }
  it { should have_many(:admission_applications).dependent(:destroy) }
  it { should have_many(:admission_pendencies).dependent(:destroy) }
  it { should have_many(:admission_process_rankings).dependent(:nullify) }

  it { should belong_to(:approval_condition).required(false) }
  it { should belong_to(:keep_in_phase_condition).required(false) }
  it { should belong_to(:member_form).required(false) }
  it { should belong_to(:shared_form).required(false) }
  it { should belong_to(:consolidation_form).required(false) }
  it { should belong_to(:candidate_form).required(false) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_phase) do
    Admissions::AdmissionPhase.new(
      name: "Fase 1",
      can_edit_candidate: false,
      candidate_can_see_member: false,
      candidate_can_see_shared: false,
      candidate_can_see_consolidation: false,
    )
  end
  subject { admission_phase }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
  end
  describe "Duplication" do
    # ToDo: initialize_dup
  end
  describe "Methods" do
    # ToDo: committee_users_for_candidate
    # ToDo: update_pendencies
    # ToDo: create_pendencies_for_candidate
    # ToDo: prepare_application_forms
  end
end
