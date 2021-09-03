require 'spec_helper'

RSpec.describe EnrollmentRequestComment, type: :model do
  let(:enrollment_request_comment) { EnrollmentRequestComment.new }
  subject { enrollment_request_comment }
  describe "Validations" do
    describe "message" do
      context "should be valid when" do
        it "message is not null" do
          enrollment_request_comment.message = "abc"
          expect(enrollment_request_comment).to have(0).errors_on :message
        end
      end
      context "should have error blank when" do
        it "message is null" do
          enrollment_request_comment.message = nil
          expect(enrollment_request_comment).to have_error(:blank).on :message
        end
      end
    end
    describe "enrollment_request" do
      context "should be valid when" do
        it "enrollment_request is not null" do
          enrollment_request_comment.enrollment_request = EnrollmentRequest.new
          expect(enrollment_request_comment).to have(0).errors_on :enrollment_request
        end
      end
      context "should have error blank when" do
        it "enrollment_request is null" do
          enrollment_request_comment.enrollment_request = nil
          expect(enrollment_request_comment).to have_error(:blank).on :enrollment_request
        end
      end
    end
    describe "user" do
      context "should be valid when" do
        it "user is not null" do
          enrollment_request_comment.user = User.new
          expect(enrollment_request_comment).to have(0).errors_on :user
        end
      end
      context "should have error blank when" do
        it "user is null" do
          enrollment_request_comment.user = nil
          expect(enrollment_request_comment).to have_error(:blank).on :user
        end
      end
    end
  end
end
