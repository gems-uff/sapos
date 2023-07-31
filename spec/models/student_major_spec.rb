# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe StudentMajor, type: :model do
  let(:student) { FactoryBot.build(:student) }
  let(:major) { FactoryBot.build(:major) }
  let(:student_major) do
    StudentMajor.new(
      student: student,
      major: major
    )
  end
  subject { student_major }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:student).required(true) }
    it { should belong_to(:major).required(true) }
    it { should validate_uniqueness_of(:student).scoped_to(:major_id).with_message(:unique_pair) }
  end
end
