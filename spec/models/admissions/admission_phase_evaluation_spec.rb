# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionPhaseEvaluation, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:admission_phase).required(true) }
  it { should belong_to(:user).required(true) }
  it { should belong_to(:admission_application).required(true) }
  it { should belong_to(:filled_form).required(true) }

  before(:all) do
    @destroy_later = []
    @admission_phase = FactoryBot.create(:admission_phase, :with_member_form)
    @role = FactoryBot.create(:role_professor)
    @user = FactoryBot.create(:user, email: "abc@def.com")
    @user_role = FactoryBot.create(:user_role, user: @user, role: @role)
    @user.update!(actual_role: @role.id)
    @admission_application = FactoryBot.create(:admission_application)
    @filled_form = FactoryBot.create(:filled_form)
  end
  after(:all) do
    @admission_phase.delete
    @user.delete
    @role.delete
    @user_role.delete
    @admission_application.delete
    @filled_form.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_phase_evaluation) do
    Admissions::AdmissionPhaseEvaluation.new(
      admission_phase: @admission_phase,
      user: @user,
      admission_application: @admission_application,
      filled_form: @filled_form
    )
  end
  subject { admission_phase_evaluation }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:admission_phase_id).scoped_to([:admission_application_id, :user_id]) }
  end
  # ToDo: test after_initialize

  describe "Methods" do
    # ToDo: to_label
  end
end
