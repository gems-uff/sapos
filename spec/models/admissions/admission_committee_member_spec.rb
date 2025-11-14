# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionCommitteeMember, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:admission_committee).required(true) }
  it { should belong_to(:user).required(true) }

  before(:all) do
    @admission_committee = FactoryBot.create(:admission_committee)
    @user = FactoryBot.create(:user, :professor)
    @destroy_later = []
  end
  after(:all) do
    @admission_committee.delete
    @user.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_committee_member) do
    Admissions::AdmissionCommitteeMember.new(
      admission_committee: @admission_committee,
      user: @user
    )
  end
  subject { admission_committee_member }
  describe "Validations" do
    it { should be_valid }
  end
  # ToDo: test after_commit

  describe "Methods" do
    # ToDo: to_label
  end
end
