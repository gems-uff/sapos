# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe Notifier, type: :model do
  let(:body) do
    "Prezado professor,\n" \
    "\n" \
    "Seguem as inscricoes:\n" \
    "- Alquimia\n" \
    "- Pocoes\n"
  end
  let(:message) do
    {
      to: "professor@example.com",
      subject: "SAPOS: teste",
      body: body.dup
    }
  end

  before(:each) do
    ActionMailer::Base.deliveries.clear
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
    CustomVariable.destroy_all
  end

  def delivered
    ActionMailer::Base.deliveries.last
  end

  describe "send_emails" do
    context "envelope" do
      it "delivers to the recipients of the message" do
        Notifier.send_emails(notifications: [message])
        expect(delivered.to).to eq(["professor@example.com"])
        expect(delivered.subject).to eq("SAPOS: teste")
      end

      it "splits a comma separated list of recipients" do
        message[:to] = "a@example.com, b@example.com"
        Notifier.send_emails(notifications: [message])
        expect(delivered.to).to eq(["a@example.com", "b@example.com"])
      end

      it "does not deliver when the message has no recipient" do
        message[:to] = ""
        Notifier.send_emails(notifications: [message])
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      it "does not deliver when the message is marked to be skipped" do
        message[:skip_message] = true
        Notifier.send_emails(notifications: [message])
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      it "does not deliver when redirect_email is set to an empty string" do
        FactoryBot.create(
          :custom_variable, variable: "redirect_email", value: ""
        )
        Notifier.send_emails(notifications: [message])
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      it "redirects the message when redirect_email is set" do
        FactoryBot.create(
          :custom_variable, variable: "redirect_email",
          value: "redirecionado@example.com"
        )
        Notifier.send_emails(notifications: [message])
        expect(delivered.to).to eq(["redirecionado@example.com"])
      end

      it "sets reply_to from the reply_to custom variable" do
        FactoryBot.create(
          :custom_variable, variable: "reply_to", value: "resposta@example.com"
        )
        Notifier.send_emails(notifications: [message])
        expect(delivered.reply_to).to eq(["resposta@example.com"])
      end

      it "overrides the reply_to of the message with the custom variable" do
        # CustomVariable.reply_to falls back to the default sender address,
        # so it always takes precedence over the reply_to of the message.
        message[:reply_to] = "resposta@example.com"
        Notifier.send_emails(notifications: [message])
        default_from = Mail::Address.new(ActionMailer::Base.default[:from])
        expect(delivered.reply_to).to eq([default_from.address])
      end
    end

    context "body" do
      it "keeps the body of the message in the text part" do
        Notifier.send_emails(notifications: [message])
        expect(delivered.text_part.decoded).to include("Prezado professor,")
        expect(delivered.text_part.decoded).to include("- Alquimia")
      end

      it "appends the notification footer to the body" do
        FactoryBot.create(
          :custom_variable, variable: "notification_footer",
          value: "Nao responda este e-mail."
        )
        Notifier.send_emails(notifications: [message])
        expect(delivered.text_part.decoded).to include("Nao responda este e-mail.")
      end

      it "does not append the notification footer when it is skipped" do
        FactoryBot.create(
          :custom_variable, variable: "notification_footer",
          value: "Nao responda este e-mail."
        )
        message[:skip_footer] = true
        Notifier.send_emails(notifications: [message])
        expect(delivered.text_part.decoded).not_to include("Nao responda este e-mail.")
      end
    end

    context "attachments" do
      it "attaches the files of the message" do
        attachments = {
          message => {
            grades_report_pdf: {
              file_name: "boletim.pdf", file_contents: "conteudo do pdf"
            }
          }
        }
        Notifier.send_emails(
          notifications: [message], notifications_attachments: attachments
        )
        expect(delivered.attachments.size).to eq(1)
        expect(delivered.attachments.first.filename).to eq("boletim.pdf")
      end
    end

    context "log" do
      it "logs the delivered notification" do
        expect do
          Notifier.send_emails(notifications: [message])
        end.to change { NotificationLog.count }.by(1)
        log = NotificationLog.last
        expect(log.to).to eq("professor@example.com")
        expect(log.subject).to eq("SAPOS: teste")
      end
    end
  end
end
