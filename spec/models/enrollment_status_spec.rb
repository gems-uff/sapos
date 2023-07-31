# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe EnrollmentStatus, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:enrollments).dependent(:restrict_with_exception) }

  let(:enrollment_status) { EnrollmentStatus.new(name: "status") }
  subject { enrollment_status }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:name) }
  end
end
