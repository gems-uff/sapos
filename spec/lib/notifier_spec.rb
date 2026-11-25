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

      it "sets every reply_to of a comma separated custom variable" do
        FactoryBot.create(
          :custom_variable, variable: "reply_to",
          value: "a@example.com, b@example.com"
        )
        Notifier.send_emails(notifications: [message])
        expect(delivered.reply_to).to eq(["a@example.com", "b@example.com"])
      end

      it "replies to the sender when the custom variable is not declared" do
        # CustomVariable.reply_to falls back to the default sender address
        default_from = Mail::Address.new(ActionMailer::Base.default[:from])
        Notifier.send_emails(notifications: [message])
        expect(delivered.reply_to).to eq([default_from.address])
      end

      it "has no reply_to when the custom variable is declared without value" do
        FactoryBot.create(:custom_variable, variable: "reply_to", value: "")
        Notifier.send_emails(notifications: [message])
        expect(delivered.reply_to).to be_nil
        expect(delivered.to_s).not_to include("Reply-To")
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

    context "data that a formatter escaped into the body" do
      # The data is escaped when the template is rendered, so the body that
      # reaches the notifier is markup. These specs pin down that the html
      # part keeps the escape and the text part reads it back.
      def rendered(template, data)
        LiquidFormatter.new(data).format(template, escape_data: :html)
      end

      let(:tricky) { "Fulano <fulano@uff.br> tem CR < 7 em P&D" }

      it "keeps the escaped data in the html part" do
        message[:body] = rendered("{{ d }}", { "d" => tricky })
        Notifier.send_emails(notifications: [message])
        html = delivered.html_part.decoded
        expect(html).to include("&lt;fulano@uff.br&gt;")
        expect(html).to include("CR &lt; 7 em P&amp;D")
      end

      it "reads the escaped data back in the text part" do
        message[:body] = rendered("{{ d }}", { "d" => tricky })
        Notifier.send_emails(notifications: [message])
        expect(delivered.text_part.decoded).to include(tricky)
      end

      it "does not let a title that looks like markup format the message" do
        title = "Um estudo sobre o uso de <strong> nos CLAUDE.md"
        message[:body] = rendered("Tese: {{ d }}", { "d" => title })
        Notifier.send_emails(notifications: [message])
        expect(delivered.html_part.decoded).not_to include("<strong>")
        expect(delivered.text_part.decoded).to include(title)
      end

      it "keeps the markup that an administrator wrote in the footer" do
        FactoryBot.create(
          :custom_variable, variable: "notification_footer",
          value: "<strong>Nao responda</strong> este e-mail"
        )
        Notifier.send_emails(notifications: [message])
        expect(delivered.html_part.decoded)
          .to include("<strong>Nao responda</strong>")
        expect(delivered.text_part.decoded).to include("Nao responda este e-mail")
      end

      it "escapes the recipient it announces when redirecting" do
        FactoryBot.create(
          :custom_variable, variable: "redirect_email", value: "dev@uff.br"
        )
        message[:to] = "Fulano <fulano@uff.br>"
        Notifier.send_emails(notifications: [message])
        expect(delivered.html_part.decoded).to include("&lt;fulano@uff.br&gt;")
        expect(delivered.text_part.decoded)
          .to include("Originalmente para Fulano <fulano@uff.br>")
      end

      it "keeps the markup that the template wrote around the data" do
        message[:body] = rendered(
          "<strong>{{ d }}</strong>", { "d" => "<em>x</em>" }
        )
        Notifier.send_emails(notifications: [message])
        expect(delivered.html_part.decoded)
          .to include("<strong>&lt;em&gt;x&lt;/em&gt;</strong>")
      end
    end

    describe "plain_body" do
      it "reads the entities back as the characters they stand for" do
        expect(Notifier.plain_body("CR &lt; 7 e P&amp;D")).to eq("CR < 7 e P&D")
      end

      it "removes the markup of the toolbar" do
        body = "<strong>Aviso</strong>\n" \
          "<div style=\"text-align: center;\">Centralizado</div>"
        expect(Notifier.plain_body(body)).to eq("Aviso\nCentralizado")
      end

      it "removes the markup that the author of a template wrote" do
        expect(Notifier.plain_body("veja o <a href=\"http://uff.br\">SAPOS</a>"))
          .to eq("veja o SAPOS")
      end

      it "reads a line break as a line break" do
        expect(Notifier.plain_body("a<br />b<br>c")).to eq("a\nb\nc")
      end

      it "handles an empty body" do
        expect(Notifier.plain_body(nil)).to eq("")
        expect(Notifier.plain_body("")).to eq("")
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

      # The server log is read by whoever operates the machine and is kept in
      # rotated files and backups. A body carries what was written for the
      # recipient alone: an application code, a grade, a link that opens a
      # record. The NotificationLog above is the place of the body, behind
      # the permissions of the application.
      context "of the server" do
        let(:lines) { [] }

        before(:each) do
          allow(Notifier.logger).to receive(:info) { |text| lines << text.to_s }
          message[:body] = "Seu codigo: SEGREDO-DA-MENSAGEM"
          Notifier.send_emails(notifications: [message])
        end

        it "tells who was notified and about what" do
          expect(lines.join("\n")).to include("professor@example.com", "SAPOS: teste")
        end

        it "does not copy the body of the message" do
          expect(lines.join("\n")).not_to include("SEGREDO-DA-MENSAGEM")
        end
      end
    end

    # The messages are sent from model callbacks and controllers, in the
    # middle of a save that can still be refused. A message announces what was
    # saved, so it waits for the transaction to commit.
    # send_emails is the way in: it holds the switches that turn delivery off
    # (should_run?, an empty redirect_email) and waits for the commit. The
    # delivery behind it is not a second way in that skips them.
    context "the delivery behind it" do
      it "control: send_emails is the way in" do
        expect(Notifier).to respond_to(:send_emails)
      end

      it "is not called from outside" do
        expect(Notifier).not_to respond_to(:deliver_emails)
      end
    end

    context "a transaction open around it" do
      def sent
        ActionMailer::Base.deliveries.size
      end

      it "control: without a transaction, delivers at once" do
        Notifier.send_emails(notifications: [message])

        expect(sent).to eq(1)
      end

      it "delivers only after the commit" do
        during = nil
        ActiveRecord::Base.transaction do
          Notifier.send_emails(notifications: [message])
          during = sent
        end

        expect(during).to eq(0)
        expect(sent).to eq(1)
        expect(NotificationLog.count).to eq(1)
      end

      it "does not deliver when the transaction is rolled back" do
        ActiveRecord::Base.transaction do
          Notifier.send_emails(notifications: [message])
          raise ActiveRecord::Rollback
        end

        expect(sent).to eq(0)
        expect(NotificationLog.count).to eq(0)
      end

      it "does not deliver when the outer transaction is rolled back" do
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.transaction(requires_new: true) do
            Notifier.send_emails(notifications: [message])
          end
          raise ActiveRecord::Rollback
        end

        expect(sent).to eq(0)
      end
    end

    # What fails after the commit can no longer undo the save. A message that
    # is not delivered, or not logged, costs only itself: the save stands, the
    # other messages are delivered, the other callbacks of the commit run, and
    # the failure is reported.
    context "a failure after the commit" do
      let(:messages) do
        %w[primeiro segundo].map do |name|
          message.merge(to: "#{name}@example.com", subject: name, body: body.dup)
        end
      end
      let(:errors) { [] }

      before(:each) do
        allow(Notifier.logger).to receive(:error) { |text| errors << text.to_s }
        allow(ExceptionNotifier).to receive(:notify_exception)
      end

      def save_and_send
        outcome = { other_callback: false }
        ActiveRecord::Base.transaction do
          outcome[:level] = FactoryBot.create(:level, name: "Nivel do envio")
          Notifier.send_emails(notifications: messages)
          ActiveRecord.after_all_transactions_commit { outcome[:other_callback] = true }
        end
        outcome
      end

      def fail_first(klass, method, error)
        calls = 0
        allow_any_instance_of(klass).to receive(method).and_wrap_original do |original, *args|
          calls += 1
          raise error if calls == 1
          original.call(*args)
        end
      end

      it "control: without a failure, every message is delivered and logged" do
        outcome = save_and_send

        expect(Level.exists?(outcome[:level].id)).to be(true)
        expect(ActionMailer::Base.deliveries.map(&:subject)).to eq(%w[primeiro segundo])
        expect(NotificationLog.pluck(:subject)).to contain_exactly("primeiro", "segundo")
        expect(outcome[:other_callback]).to be(true)
        expect(ExceptionNotifier).not_to have_received(:notify_exception)
      end

      it "keeps the save and the rest when a delivery fails" do
        fail_first(Mail::TestMailer, :deliver!, Errno::ECONNREFUSED)

        outcome = nil
        expect { outcome = save_and_send }.not_to raise_error

        expect(Level.exists?(outcome[:level].id)).to be(true)
        expect(ActionMailer::Base.deliveries.map(&:subject)).to eq(%w[segundo])
        expect(NotificationLog.pluck(:subject)).to eq(%w[segundo])
        expect(outcome[:other_callback]).to be(true)
        expect(ExceptionNotifier).to have_received(:notify_exception)
          .with(an_instance_of(Errno::ECONNREFUSED), data: { notification_id: nil, delivered: false }).once
        expect(errors.join("\n")).to include("Errno::ECONNREFUSED", "primeiro@example.com", "primeiro")
      end

      it "keeps the save and the rest when the log of a delivery fails" do
        fail_first(NotificationLog, :save, ActiveRecord::ConnectionNotEstablished)

        outcome = nil
        expect { outcome = save_and_send }.not_to raise_error

        expect(Level.exists?(outcome[:level].id)).to be(true)
        expect(ActionMailer::Base.deliveries.map(&:subject)).to eq(%w[primeiro segundo])
        expect(NotificationLog.pluck(:subject)).to eq(%w[segundo])
        expect(outcome[:other_callback]).to be(true)
        expect(ExceptionNotifier).to have_received(:notify_exception)
          .with(an_instance_of(ActiveRecord::ConnectionNotEstablished), data: { notification_id: nil, delivered: true }).once
      end

      # The operator reads the server log to decide whether to send again: a
      # message that was delivered and only failed to be logged must not read
      # as not delivered, or the recipient gets it twice.
      it "control: a failed delivery is logged as not delivered" do
        fail_first(Mail::TestMailer, :deliver!, Errno::ECONNREFUSED)

        save_and_send

        expect(errors.join("\n")).to include("Notification not delivered")
      end

      it "tells a failure after the log from one before it" do
        calls = 0
        allow(Notifier).to receive(:display_notification_info).and_wrap_original do |original, *args|
          calls += 1
          raise IOError if calls == 1
          original.call(*args)
        end

        save_and_send

        expect(NotificationLog.pluck(:subject)).to contain_exactly("primeiro", "segundo")
        expect(errors.join("\n")).not_to include("not logged")
        expect(errors.join("\n")).to include("Notification delivered and logged")
      end

      it "tells a delivered message whose log failed from one not delivered" do
        fail_first(NotificationLog, :save, ActiveRecord::ConnectionNotEstablished)

        save_and_send

        expect(errors.join("\n")).not_to include("Notification not delivered")
        expect(errors.join("\n")).to include("Notification delivered, but not logged")
      end

      # A failure that hits every message of a call -- the mail server down
      # during the daily run -- is one error email, not one per message. The
      # server log keeps a line for each message.
      it "reports the same failure of one call in one error email" do
        allow_any_instance_of(Mail::TestMailer).to receive(:deliver!).and_raise(Errno::ECONNREFUSED)

        save_and_send

        expect(ExceptionNotifier).to have_received(:notify_exception).once
        expect(ExceptionNotifier).to have_received(:notify_exception)
          .with(an_instance_of(Errno::ECONNREFUSED), data: { notification_id: nil, delivered: false })
        expect(errors.join("\n")).to include("primeiro@example.com", "segundo@example.com")
      end

      # Two different failures in one call -- the daily run puts every due
      # notification in one -- are two defects, and each one reaches the
      # error email with the notification it came from.
      it "reports each kind of failure of one call" do
        messages.first[:notification_id] = 5
        messages.last[:notification_id] = 9
        fail_first(Mail::TestMailer, :deliver!, Errno::ECONNREFUSED)
        fail_first(NotificationLog, :save, ActiveRecord::ConnectionNotEstablished)

        save_and_send

        expect(ExceptionNotifier).to have_received(:notify_exception).twice
        expect(ExceptionNotifier).to have_received(:notify_exception)
          .with(an_instance_of(Errno::ECONNREFUSED), data: hash_including(notification_id: 5, delivered: false))
        expect(ExceptionNotifier).to have_received(:notify_exception)
          .with(an_instance_of(ActiveRecord::ConnectionNotEstablished),
            data: hash_including(notification_id: 9, delivered: true))
      end

      # Every failure of sendmail, the delivery of production, is a
      # Mail::Sendmail::DeliveryError: its exit status is what tells one
      # defect from another, and the recipient is not.
      def sendmail_failure(status, recipient)
        Mail::Sendmail::DeliveryError.new(
          "Delivery failed with exitstatus #{status}: " \
          "[\"/usr/sbin/sendmail\", \"-i\", \"-f\", \"sapos@example.com\", \"--\", \"#{recipient}\"]"
        )
      end

      def fail_each(*failures)
        allow_any_instance_of(Mail::TestMailer).to receive(:deliver!) { raise failures.shift }
      end

      it "control: reports the same sendmail failure to different recipients once" do
        fail_each(sendmail_failure(75, "primeiro@example.com"), sendmail_failure(75, "segundo@example.com"))

        save_and_send

        expect(ExceptionNotifier).to have_received(:notify_exception).once
      end

      it "reports each sendmail failure of one call" do
        fail_each(sendmail_failure(67, "primeiro@example.com"), sendmail_failure(75, "segundo@example.com"))
        reported = []
        allow(ExceptionNotifier).to receive(:notify_exception) { |error, **| reported << error.message }

        save_and_send

        expect(reported.size).to eq(2)
        expect(reported).to contain_exactly(include("exitstatus 67"), include("exitstatus 75"))
      end

      # The error email does not wait for the rest of the call: with the
      # mail server down, every message waits for its own timeout, and a
      # process killed before the end would not report at all.
      it "reports a failure before delivering the messages after it" do
        delivered_before_report = nil
        allow(ExceptionNotifier).to receive(:notify_exception) do
          delivered_before_report = ActionMailer::Base.deliveries.size
        end
        fail_first(Mail::TestMailer, :deliver!, Errno::ECONNREFUSED)

        save_and_send

        expect(delivered_before_report).to eq(0)
        expect(ActionMailer::Base.deliveries.map(&:subject)).to eq(%w[segundo])
      end

      # A message of an email template (admissions, enrollment) belongs to
      # no notification.
      it "does not name a notification that the message does not have" do
        fail_first(Mail::TestMailer, :deliver!, Errno::ECONNREFUSED)
        warnings = []
        allow(Notifier.logger).to receive(:warn) { |text| warnings << text.to_s }
        messages.last[:to] = ""

        save_and_send

        expect(errors.grep(/not delivered/).first).to start_with("Notification not delivered: Errno::ECONNREFUSED")
        expect(warnings.first).to eq("Notification not delivered: no recipient")
      end

      it "names the notification of each failure in the server log" do
        messages.each { |m| m[:notification_id] = 7 }
        allow_any_instance_of(Mail::TestMailer).to receive(:deliver!).and_raise(Errno::ECONNREFUSED)

        save_and_send

        expect(errors.grep(/not delivered/).size).to eq(2)
        expect(errors.grep(/not delivered/)).to all(include("notification 7"))
      end

      # What the screens that announce a delivery read (see
      # Admissions::ProcessBaseController#token_delivery_flash).
      describe "the messages it returns" do
        it "control: none, when every message is delivered" do
          expect(Notifier.send_emails(notifications: messages)).to eq([])
        end

        it "the ones not delivered, when it delivers at once" do
          fail_first(Mail::TestMailer, :deliver!, Errno::ECONNREFUSED)

          expect(Notifier.send_emails(notifications: messages)).to eq([messages.first])
        end

        # A template whose recipient renders empty (a misspelled variable,
        # a student without an email) delivers nothing, and the screen
        # cannot announce it.
        it "the ones without a recipient, which it logs" do
          warnings = []
          allow(Notifier.logger).to receive(:warn) { |text| warnings << text.to_s }
          messages.first[:to] = ""
          messages.first[:notification_id] = 3

          expect(Notifier.send_emails(notifications: messages)).to eq([messages.first])
          expect(ActionMailer::Base.deliveries.map(&:subject)).to eq(%w[segundo])
          expect(warnings.join("\n")).to include("not delivered (notification 3): no recipient", "primeiro")
          expect(ExceptionNotifier).not_to have_received(:notify_exception)
        end

        it "not the ones delivered whose log failed" do
          fail_first(NotificationLog, :save, ActiveRecord::ConnectionNotEstablished)

          expect(Notifier.send_emails(notifications: messages)).to eq([])
        end

        it "nothing, when the delivery waits for the commit" do
          returned = :not_called
          ActiveRecord::Base.transaction do
            returned = Notifier.send_emails(notifications: messages)
          end

          expect(returned).to be_nil
        end
      end

      # Production delivers through sendmail, whose failure message carries
      # the whole command, recipient included. The error email takes only
      # technical data (config.x.error_email): the address stays in the
      # server log, next to the notification it came from.
      describe "an address in the failure" do
        let(:sendmail_failure) do
          Mail::Sendmail::DeliveryError.new(
            'Delivery failed with exitstatus 75: ["/usr/sbin/sendmail", "-i", ' \
            '"-f", "sapos@example.com", "--", "primeiro@example.com"]'
          )
        end

        before(:each) do
          @reported = []
          allow(ExceptionNotifier).to receive(:notify_exception) { |error, **| @reported << error }
          fail_first(Mail::TestMailer, :deliver!, sendmail_failure)
        end

        it "control: the server log keeps the address" do
          save_and_send

          expect(errors.join("\n")).to include("primeiro@example.com")
        end

        it "does not go to the error email, and the rest of the failure does" do
          save_and_send

          expect(@reported.size).to eq(1)
          reported = @reported.first
          expect(reported).to be_a(Mail::Sendmail::DeliveryError)
          expect(reported.message).not_to include("@example.com")
          expect(reported.message).to include("exitstatus 75", "/usr/sbin/sendmail")
          expect(reported.backtrace).to be_present
        end

        # A recipient that is not an address -- a template that puts the
        # name of the student where the address goes -- reaches the command
        # as it is, and the mask of the address leaves the name.
        it "does not take a malformed recipient to the error email" do
          malformed = Mail::Sendmail::DeliveryError.new(
            'Delivery failed with exitstatus 67: ["/usr/sbin/sendmail", "-i", ' \
            '"-f", "sapos@example.com", "--", "Fulano da Silva <fulano@example.com", "Beltrana Souza"]'
          )
          fail_first(Mail::TestMailer, :deliver!, malformed)

          save_and_send

          expect(@reported.size).to eq(1)
          expect(@reported.first.message).not_to include("Fulano", "Silva", "Beltrana", "@example.com")
          expect(@reported.first.message).to include("exitstatus 67", "/usr/sbin/sendmail", '"-f"')
        end

        it "does not go to the error email from an SMTP refusal either" do
          refusal = Net::SMTPFatalError.new(
            Net::SMTP::Response.parse("550 5.1.1 <segundo@example.com>: mailbox unavailable")
          )
          fail_first(Mail::TestMailer, :deliver!, refusal)

          save_and_send

          expect(@reported.first).to be_a(Net::SMTPFatalError)
          expect(@reported.first.message).to eq("550 5.1.1 <<address>>: mailbox unavailable")
        end
      end

      it "does not copy the body of the message into the server log" do
        messages.first[:body] = "Seu codigo: SEGREDO-DA-MENSAGEM"
        fail_first(Mail::TestMailer, :deliver!, Errno::ECONNREFUSED)

        save_and_send

        expect(errors).not_to be_empty
        expect(errors.join("\n")).not_to include("SEGREDO-DA-MENSAGEM")
      end
    end

    # The SMTP server refuses one recipient (550) and mail.deliver! raises.
    # The messages are delivered one by one, so a refusal in the middle of a
    # batch -- an individual notification, or the daily run of
    # maintenance:trigger_notifications -- must not cost the messages after it
    # (issue #699). send_emails reports the failure instead of raising it
    # (see "a failure after the commit").
    context "a message refused by the server" do
      let(:messages) do
        %w[primeiro recusado terceiro].map do |name|
          message.merge(to: "#{name}@example.com", body: body.dup)
        end
      end

      def send_all
        Notifier.send_emails(notifications: messages)
      end

      def delivered_to
        ActionMailer::Base.deliveries.flat_map(&:to)
      end

      it "control: without the refusal, every message is delivered and logged" do
        send_all

        expect(delivered_to).to eq(%w[primeiro@example.com recusado@example.com terceiro@example.com])
        expect(NotificationLog.pluck(:to)).to contain_exactly(
          "primeiro@example.com", "recusado@example.com", "terceiro@example.com"
        )
      end

      it "does not keep the messages after it from being delivered" do
        allow_any_instance_of(Mail::TestMailer).to receive(:deliver!).and_wrap_original do |original, mail|
          if mail.to.include?("recusado@example.com")
            raise Net::SMTPFatalError.new(Net::SMTP::Response.parse("550 5.1.1 mailbox unavailable"))
          end
          original.call(mail)
        end

        send_all

        expect(delivered_to).to eq(%w[primeiro@example.com terceiro@example.com])
        expect(NotificationLog.pluck(:to)).to contain_exactly("primeiro@example.com", "terceiro@example.com")
      end
    end
  end
end
