# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe EnrollmentRequestComment, type: :model do
  it { should be_able_to_be_destroyed }

  let(:enrollment_request) { FactoryBot.build(:enrollment_request) }
  let(:user) { FactoryBot.build(:user) }
  let(:enrollment_request_comment) do
    EnrollmentRequestComment.new(
      enrollment_request: enrollment_request,
      user: user,
      message: "Comment"
    )
  end
  subject { enrollment_request_comment }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:enrollment_request).required(true) }
    it { should belong_to(:user).required(true) }
    it { should validate_presence_of(:message) }
  end
end
