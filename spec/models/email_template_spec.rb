require 'spec_helper'

describe EmailTemplate do
  let(:email_template) { EmailTemplate.new }
  subject { email_template }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is unique" do
          email_template.name = "asas"
          expect(email_template).to have(0).errors_on :name
        end

        it "name is blank" do
          FactoryBot.create(:email_template, name: "")
          email_template.name = ""
          expect(email_template).to have(0).errors_on :name
        end
      end
      context "should have error uniqueness when" do
        it "already exists another email template for the same name" do
          FactoryBot.create(:email_template, name: "temp")
          email_template.name = "temp"
          expect(email_template).to have_error(:taken).on :name
        end
      end
    end
    describe "body" do
      context "should be valid when" do
        it "body is not null" do
          email_template.body = "asas"
          expect(email_template).to have(0).errors_on :body
        end
      end
      context "should have error blank when" do
        it "body is null" do
          email_template.body = nil
          expect(email_template).to have_error(:blank).on :body
        end
        it "body is empty" do
          email_template.body = ""
          expect(email_template).to have_error(:blank).on :body
        end
      end
    end
    describe "to" do
      context "should be valid when" do
        it "to is not null" do
          email_template.to = "asas"
          expect(email_template).to have(0).errors_on :to
        end
      end
      context "should have error blank when" do
        it "to is null" do
          email_template.to = nil
          expect(email_template).to have_error(:blank).on :to
        end
        it "to is empty" do
          email_template.to = ""
          expect(email_template).to have_error(:blank).on :to
        end
      end
    end
    describe "subject" do
      context "should be valid when" do
        it "subject is not null" do
          email_template.subject = "asas"
          expect(email_template).to have(0).errors_on :subject
        end
      end
      context "should have error blank when" do
        it "subject is null" do
          email_template.to = nil
          expect(email_template).to have_error(:blank).on :subject
        end
        it "subject is empty" do
          email_template.subject = ""
          expect(email_template).to have_error(:blank).on :subject
        end
      end
    end
  end
end
