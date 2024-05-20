# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailTemplate, type: :model do
  it { should be_able_to_be_destroyed }

  let(:email_template) do
    EmailTemplate.new(
      name: "Template",
      body: "Hi",
      to: "a@ic.uff.com",
      subject: "Title",
    )
  end
  subject { email_template }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:body) }
    it { should validate_presence_of(:to) }
    it { should validate_presence_of(:subject) }
    it { should validate_uniqueness_of(:name).allow_blank }
  end
  describe "Methods" do
    describe "devise_template" do
      context "should load a devise template by the devise mailer action when" do
        it "the action is confirmation_instructions" do
          result = EmailTemplate.devise_template(:confirmation_instructions)
          expected = EmailTemplate.load_template("devise:confirmation_instructions")
          expect(result).to have_attributes(to: expected.to, subject: expected.subject, body: expected.body)
        end
        it "the action is email_changed" do
          result = EmailTemplate.devise_template(:email_changed)
          expected = EmailTemplate.load_template("devise:email_changed")
          expect(result).to have_attributes(to: expected.to, subject: expected.subject, body: expected.body)
        end
        it "the action is invitation_instructions" do
          result = EmailTemplate.devise_template(:invitation_instructions)
          expected = EmailTemplate.load_template("devise:invitation_instructions")
          expect(result).to have_attributes(to: expected.to, subject: expected.subject, body: expected.body)
        end
        it "the action is password_change" do
          result = EmailTemplate.devise_template(:password_change)
          expected = EmailTemplate.load_template("devise:password_change")
          expect(result).to have_attributes(to: expected.to, subject: expected.subject, body: expected.body)
        end
        it "the action is reset_password_instructions" do
          result = EmailTemplate.devise_template(:reset_password_instructions)
          expected = EmailTemplate.load_template("devise:reset_password_instructions")
          expect(result).to have_attributes(to: expected.to, subject: expected.subject, body: expected.body)
        end
        it "the action is unlock_instructions" do
          result = EmailTemplate.devise_template(:unlock_instructions)
          expected = EmailTemplate.load_template("devise:unlock_instructions")
          expect(result).to have_attributes(to: expected.to, subject: expected.subject, body: expected.body)
        end
      end
    end
    describe "load_template" do
      it "should load a builtin template if it does not exist in the database" do
        template = EmailTemplate.load_template("accomplishments:email_to_advisor")
        expect(template).to have_attributes(
          to: "<%= var(:advisement).professor.email %>",
          subject: I18n.t("notifications.accomplishment.email_to_advisor.subject"),
          body: File.read(File.join(Rails.root, "app", "views", File.join("accomplishments", "mailer", "email_to_advisor.text.erb")))
        )
      end

      it "should return an existing template if it is stored" do
        FactoryBot.create(
          :email_template, name: "accomplishments:email_to_advisor", to: "a", subject: "b", body: "c"
        )

        template = EmailTemplate.load_template("accomplishments:email_to_advisor")
        expect(template).to have_attributes(
          to: "a",
          subject: "b",
          body: "c"
        )
        EmailTemplate.delete_all
      end
    end
    describe "update_mailer_headers" do
      it "should add attributes to the email" do
        template = EmailTemplate.load_template("accomplishments:email_to_advisor")
        template.enabled = false

        headers = {
          to: "a", subject: "b", body: "c"
        }
        template.update_mailer_headers(headers)
        expect(headers).to eq({
          to: "a", subject: "b", body: "c",
          skip_message: true, skip_footer: true
        })
      end
      it "should change 'to' attribute when redirect_email is set" do
        FactoryBot.create(:custom_variable, variable: "redirect_email", value: "email@email.com")
        template = EmailTemplate.load_template("accomplishments:email_to_advisor")

        headers = {
          to: "a", subject: "b", body: "c"
        }
        template.update_mailer_headers(headers)
        expect(headers).to eq({
          to: "email@email.com", subject: "b (Originalmente para a)", body: "c",
          skip_message: false, skip_footer: true, skip_redirect: true
        })
        CustomVariable.delete_all
      end
      it "should have 'reply_to' attribute when reply_to is set" do
        FactoryBot.create(:custom_variable, variable: "reply_to", value: "email@email.com")
        template = EmailTemplate.load_template("accomplishments:email_to_advisor")

        headers = {
          to: "a", subject: "b", body: "c"
        }
        template.update_mailer_headers(headers)
        expect(headers).to eq({
                                reply_to: "email@email.com", subject: "b", body: "c", to: "a",
                                skip_message: false, skip_footer: true
                              })
        CustomVariable.delete_all
      end
    end
    describe "prepare_message" do
      it "should use the ERB formating in all fields" do
        template = FactoryBot.create(
          :email_template, enabled: false,
          to: "t<%= var(:temp) %>", subject: "s<%= var(:temp) %>", body: "b<%= var(:temp) %>"
        )
        expect(template.prepare_message(temp: 1)).to eq({
          to: "t1",
          subject: "s1",
          body: "b1",
          skip_footer: true,
          skip_message: true,
        })
      end
    end
  end
end
