# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionPendency, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:admission_phase).required(true) }
  it { should belong_to(:admission_application).required(true) }
  it { should belong_to(:user).required(false) }

  before(:all) do
    @admission_phase = FactoryBot.create(:admission_phase)
    @admission_application = FactoryBot.create(:admission_application)
    @destroy_later = []
  end
  after(:all) do
    @admission_phase.delete
    @admission_application.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_pendency) do
    Admissions::AdmissionPendency.new(
      admission_phase: @admission_phase,
      admission_application: @admission_application,
      mode: Admissions::AdmissionPendency::SHARED,
      status: Admissions::AdmissionPendency::PENDENT,
    )
  end
  subject { admission_pendency }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:mode) }
    it { should validate_inclusion_of(:mode).in_array(Admissions::AdmissionPendency::MODES) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(Admissions::AdmissionPendency::STATUSES) }
    it { should validate_uniqueness_of(:admission_phase_id).scoped_to([:admission_application_id, :user_id, :mode]) }
  end
  # ToDo: test scopes

  describe "Methods" do
    # ToDo: status_value
    # ToDo: candidate_pendencies
    # ToDo: member_pendencies
    # ToDo: shared_pendencies
  end
end
