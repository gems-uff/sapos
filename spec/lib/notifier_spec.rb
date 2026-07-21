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

    context "html body" do
      it "keeps the line breaks of the body" do
        Notifier.send_emails(notifications: [message])
        html = delivered.html_part.decoded
        expect(html).to include("Prezado professor,<br />")
        expect(html).to include("- Alquimia<br />")
      end

      it "keeps the blank lines of the body" do
        Notifier.send_emails(notifications: [message])
        html = delivered.html_part.decoded
        expect(html).to match(/Prezado professor,<br \/>\s*<br \/>\s*Seguem/)
      end

      it "keeps the indentation of the body" do
        message[:body] = "Turmas:\n    - Alquimia"
        Notifier.send_emails(notifications: [message])
        expect(delivered.html_part.decoded).to include(
          "Turmas:<br />\n&nbsp;&nbsp;&nbsp;&nbsp;- Alquimia"
        )
      end

      it "keeps the spaces used to align the body" do
        message[:body] = "Alquimia    2026/2"
        Notifier.send_emails(notifications: [message])
        expect(delivered.html_part.decoded).to include(
          "Alquimia&nbsp;&nbsp;&nbsp; 2026/2"
        )
      end

      it "keeps the markup produced by the template editor toolbar" do
        # The bold, italic and align buttons of the toolbar produce this markup
        # (the align tag of lib/liquid_formatter.rb renders the div).
        message[:body] = "<strong>Aviso</strong> e <em>obs</em>\n" \
          "<div style=\"text-align: center;\">Centralizado</div>"
        Notifier.send_emails(notifications: [message])
        html = delivered.html_part.decoded
        expect(html).to include("<strong>Aviso</strong>")
        expect(html).to include("<em>obs</em>")
        expect(html).to include("<div style=\"text-align: center;\">Centralizado</div>")
      end

      it "separates the notification footer from the body" do
        FactoryBot.create(
          :custom_variable, variable: "notification_footer",
          value: "Nao responda este e-mail."
        )
        Notifier.send_emails(notifications: [message])
        expect(delivered.html_part.decoded).to match(
          /<br \/>\s*<br \/>\s*Nao responda este e-mail\./
        )
      end

      it "does not leak the html conversion into the text part" do
        message[:body] = "Turmas:\n    - Alquimia"
        Notifier.send_emails(notifications: [message])
        text = delivered.text_part.decoded
        expect(text).not_to include("<br />")
        expect(text).not_to include("&nbsp;")
        expect(text).to include("Turmas:\n    - Alquimia")
      end
    end

    context "data that looks like markup" do
      let(:tricky) { "Fulano <fulano@uff.br> tem CR < 7 em P&D" }

      it "escapes the data of the body in the html part" do
        message[:body] = tricky
        Notifier.send_emails(notifications: [message])
        html = delivered.html_part.decoded
        expect(html).to include("&lt;fulano@uff.br&gt;")
        expect(html).to include("CR &lt; 7 em P&amp;D")
      end

      it "keeps the data of the body untouched in the text part" do
        message[:body] = tricky
        Notifier.send_emails(notifications: [message])
        expect(delivered.text_part.decoded).to include(tricky)
      end

      it "removes the toolbar markup from the text part" do
        message[:body] = "<strong>Aviso</strong>\n" \
          "<div style=\"text-align: center;\">Centralizado</div>"
        Notifier.send_emails(notifications: [message])
        text = delivered.text_part.decoded
        expect(text).to include("Aviso\nCentralizado")
        expect(text).not_to include("<strong>")
        expect(text).not_to include("<div")
      end

      it "escapes a closing div that does not belong to an align tag" do
        message[:body] = "Fim do bloco </div> citado"
        Notifier.send_emails(notifications: [message])
        expect(delivered.html_part.decoded).to include("&lt;/div&gt;")
      end
    end

    describe "escape_body" do
      it "escapes text that is not markup" do
        expect(Notifier.escape_body("a <b> & \"c\"")).to eq(
          "a &lt;b&gt; &amp; &quot;c&quot;"
        )
      end

      it "keeps the markup of the toolbar" do
        expect(Notifier.escape_body("<strong>a</strong> <em>b</em>")).to eq(
          "<strong>a</strong> <em>b</em>"
        )
      end

      it "keeps the div of the align tag with its closing tag" do
        body = "<div style=\"text-align: right;\">a</div>"
        expect(Notifier.escape_body(body)).to eq(body)
      end

      it "handles an empty body" do
        expect(Notifier.escape_body(nil)).to eq("")
        expect(Notifier.escape_body("")).to eq("")
      end
    end

    describe "plain_body" do
      it "keeps the body as it is" do
        expect(Notifier.plain_body("CR < 7 e P&D")).to eq("CR < 7 e P&D")
      end

      it "removes the markup of the toolbar" do
        expect(Notifier.plain_body("<em>a</em> b")).to eq("a b")
      end
    end

    describe "body_whitespace_to_html" do
      it "converts every kind of line break" do
        expect(Notifier.body_whitespace_to_html("a\nb\r\nc\rd")).to eq(
          "a<br />\nb<br />\nc<br />\nd"
        )
      end

      it "converts tabs into spaces" do
        expect(Notifier.body_whitespace_to_html("a\tb")).to eq(
          "a" + ("&nbsp;" * (Notifier::TAB_WIDTH - 1)) + " b"
        )
      end

      it "keeps a single space between words" do
        expect(Notifier.body_whitespace_to_html("a b")).to eq("a b")
      end

      it "handles an empty body" do
        expect(Notifier.body_whitespace_to_html(nil)).to eq("")
        expect(Notifier.body_whitespace_to_html("")).to eq("")
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
