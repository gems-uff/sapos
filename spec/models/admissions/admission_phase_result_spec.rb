# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionPhaseResult, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:admission_phase).required(true) }
  it { should belong_to(:admission_application).required(true) }
  it { should belong_to(:filled_form).required(true) }

  before(:all) do
    @destroy_later = []
    @admission_phase = FactoryBot.create(:admission_phase, :with_shared_form)
    @admission_application = FactoryBot.create(:admission_application)
    @filled_form = FactoryBot.create(:filled_form)
  end
  after(:all) do
    @admission_phase.delete
    @admission_application.delete
    @filled_form.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_phase_result) do
    Admissions::AdmissionPhaseResult.new(
      admission_phase: @admission_phase,
      admission_application: @admission_application,
      filled_form: @filled_form,
      mode: Admissions::AdmissionPhaseResult::SHARED
    )
  end
  subject { admission_phase_result }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:admission_phase_id).scoped_to([:admission_application_id, :mode]) }
    it { should validate_presence_of(:mode) }
    it { should validate_inclusion_of(:mode).in_array(Admissions::AdmissionPhaseResult::RESULT_MODES) }
  end
  # ToDo: test after_initialize

  describe "Methods" do
    # ToDo: to_label
  end
end
