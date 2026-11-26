# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "singleton"

module Notifier
  # Number of spaces that replaces a tab when converting a body to HTML
  TAB_WIDTH = 8

  def self.logger
    Rails.logger
  end

  # Escapes a text that is written into the body of a message.
  #
  # A body is markup, so a text that was not written as markup is escaped
  # before joining it. See CodeEvaluator::ESCAPES, which does the same for the
  # data that fills a template.
  def self.as_markup(text)
    CodeEvaluator::ESCAPES[:html].call(text.to_s)
  end

  # Builds the text part of a message out of its body.
  #
  # A body is markup: the toolbar of the template editor writes some of it and
  # the author of the template is free to write more. None of it has meaning
  # when read as text, so the tags are removed and the entities are read back
  # as the characters they stand for. A line break is the one tag whose
  # removal would change the text, so it becomes a line break.
  def self.plain_body(body)
    text = body.to_s.gsub(/<br\s*\/?>/i, "\n")
    CGI.unescapeHTML(ActionController::Base.helpers.strip_tags(text))
  end

  # Converts the whitespace of a message body into its HTML equivalent.
  #
  # Notification and email templates are written as text with inline markup,
  # so the body is delivered as HTML. HTML collapses every run of whitespace,
  # which would join all the lines of the body into a single paragraph, and
  # the data that fills the template is already escaped by the formatter that
  # rendered it. Line breaks become <br> and the indentation
  # is kept with non breaking spaces, so that what is written in the template
  # is what is read in the message.
  def self.body_whitespace_to_html(body)
    lines = body.to_s.split(/\r\n|\r|\n/, -1)
    lines.map! do |line|
      line
        .gsub("\t", " " * TAB_WIDTH)
        .sub(/\A +/) { |spaces| "&nbsp;" * spaces.size }
        .gsub(/ {2,}/) { |spaces| ("&nbsp;" * (spaces.size - 1)) + " " }
    end
    lines.join("<br />\n")
  end

  def self.should_run?
    Rails.application.config.should_send_emails
  end

  # As duas chaves que fazem send_emails voltar sem enviar nada: o envio
  # desligado no ambiente e a variavel redirect_email vazia.
  def self.sending?
    should_run? && CustomVariable.redirect_email != ""
  end

  def self.send_emails(notifications)
    Notifier.logger.info "Starting send_emails function."
    unless Notifier.should_run?
      Notifier.logger.info "Execution method is not 'Server'. Stoping process."
      return
    end

    if CustomVariable.redirect_email == ""
      Notifier.logger.info "Custom Variable 'redirect_email' is empty. Stoping process."
      return
    end

    # A entrega espera a transação aberta confirmar, e não acontece se ela for
    # desfeita. Os envios saem de callbacks de modelo e de controllers, no
    # meio de gravações que ainda podem ser recusadas: entregues na hora,
    # anunciariam o que não foi gravado, e o NotificationLog do envio seria
    # desfeito com a gravação. Fora de transação, a entrega é imediata. A
    # falha de uma mensagem não sobe (report_failure).
    #
    # Devolve as mensagens que não foram entregues, a sem destinatário
    # inclusive, quando a entrega foi imediata: a tela que anuncia o envio não pode afirmar o que não saiu,
    # e com o servidor de e-mail parado nem o e-mail de erro sai. Devolve
    # nil quando a entrega não aconteceu agora (envio desligado, ou à espera
    # do commit).
    undelivered = nil
    ActiveRecord.after_all_transactions_commit do
      undelivered = deliver_emails(notifications)
    end
    undelivered
  end

  # Privado: chamado direto, pularia os portões de send_emails (envio
  # desligado, redirect_email vazio) e a espera pelo commit.

  def self.deliver_emails(notifications)
    messages = notifications[:notifications]
    messages_attachments = notifications[:notifications_attachments] || {}
    reported = Set.new
    undelivered = []

    messages.each do |message|
      delivered = false
      logged = false
      options = {}
      m = message.merge(options)
      next if m[:skip_message]
      m_attachments = messages_attachments[message]
      if !CustomVariable.notification_footer.empty? && ! m[:skip_footer]
        # a footer is written by an administrator, who writes markup like the
        # author of a template does, so it joins the body as it is
        m[:body] += "\n\n\n" + CustomVariable.notification_footer
      end
      if !CustomVariable.redirect_email.nil? && ! m[:skip_redirect]
        Notifier.logger.info "Custom Variable 'redirect_email' is set. Redirecting the emails"
        # a recipient is a header, not markup: an address such as
        # "Fulano <fulano@uff.br>" has to be escaped to be read in the body
        m[:body] = "Originalmente para #{Notifier.as_markup(m[:to])}\n\n" + m[:body]
        m[:to] = CustomVariable.redirect_email
      end
      reply_to = CustomVariable.reply_to
      if reply_to.present?
        Notifier.logger.info "Custom Variable 'reply_to' is set. Forwarding email"
        m[:reply_to] = reply_to
      end
      if m[:to].blank?
        # A recipient that renders empty -- a misspelled variable in a
        # template edited on the screen, a student without an email -- is
        # not a failure of the delivery, and does not go to the error email;
        # but nothing was delivered, and the screen that announces it has to
        # know (see send_emails).
        Notifier.logger.warn "Notification not delivered#{notification_label(message)}: no recipient"
        Notifier.logger.warn "Subject: #{message[:subject]}"
        undelivered << message
      else
        actionmailer_base = ActionMailer::Base.new

        attachments_file_name_list = nil
        if m_attachments
          attachments_file_name_list = ""
          m_attachments.keys.each do |attachment_key|
            attachment = m_attachments[attachment_key]
            actionmailer_base.attachments[attachment[:file_name]] = {
              mime_type: "application/pdf", content: attachment[:file_contents]
            }
            attachments_file_name_list += attachment[:file_name] + ", "
          end
          attachments_file_name_list = attachments_file_name_list[0..-3]
        end
        old_to = m[:to]
        m[:to] = old_to.to_s.split(",").map(&:strip).reject(&:empty?)
        old_reply_to = nil
        if m[:reply_to].is_a?(String) && !m[:reply_to].empty?
          old_reply_to = m[:reply_to]
          m[:reply_to] = old_reply_to.to_s.split(",").map(&:strip).reject(&:empty?)
        end
        # actionmailer_base.mail(m).deliver!
        mail = actionmailer_base.mail(
          to: m[:to],
          subject: m[:subject],
          reply_to: m[:reply_to]
        ) do |format|
          plain = Notifier.plain_body(m[:body])
          format.text { plain }
          format.html { Notifier.body_whitespace_to_html(m[:body]).html_safe }
        end
        mail.deliver!
        delivered = true
        m[:to] = old_to
        m[:reply_to] = old_reply_to unless old_reply_to.nil?

        NotificationLog.new(
          notification_id: m[:notification_id],
          to: m[:to],
          subject: m[:subject],
          body: m[:body],
          reply_to: m[:reply_to],
          attachments_file_names: attachments_file_name_list
        ).save
        logged = true
        Notifier.display_notification_info(m, attachments_file_name_list)
      end
    rescue StandardError => error
      Notifier.report_failure(error, message, delivered: delivered, logged: logged)
      undelivered << message unless delivered
      # one error email per kind of failure of the call, at once (see
      # notify_failure)
      kind = [error.class, Notifier.without_addresses(error).message, delivered]
      Notifier.notify_failure(error, message, delivered: delivered) if reported.add?(kind)
    end
    undelivered
  end
  private_class_method :deliver_emails

  # A message that could not be delivered or logged costs only itself. The
  # delivery runs after the commit, so raising would not undo what was saved:
  # it would turn a saved change into an error page, keep the messages after
  # this one from being delivered and skip the other callbacks of the commit.
  # The failure goes to the server log, without the body (see
  # display_notification_info), and to the error email (notify_failure, one
  # per kind of failure). The log has a line for each message, and tells a
  # message that was delivered and only failed to be logged from one that
  # was not delivered:
  # it is what the operator reads to decide whether to send it again. "Not
  # delivered" is what the application knows: deliver! did not return. The
  # mail server may still have taken the message, when the failure comes
  # after it accepted the data (a timeout on QUIT, say).
  def self.report_failure(error, message, delivered: false, logged: false)
    outcome =
      if logged then "delivered and logged, but failed after"
      elsif delivered then "delivered, but not logged"
      else "not delivered"
      end
    Notifier.logger.error "Notification #{outcome}#{notification_label(message)}: " \
      "#{error.class}: #{error.message}"
    Notifier.logger.error "Notifying: #{message[:to]}"
    Notifier.logger.error "Subject: #{message[:subject]}"
  end

  # The notification a failed message came from, for the server log. A
  # message of an email template (admissions, enrollment) has none.
  def self.notification_label(message)
    id = message[:notification_id]
    id.present? ? " (notification #{id})" : ""
  end

  # The error email, with technical data only (see config.x.error_email):
  # one per kind of failure of a call -- its class, its message without the
  # addresses, and whether the message was delivered before it --, sent at
  # once. A failure that hits every message -- the mail server down during
  # the daily run -- would otherwise be one email per message; a second,
  # different failure in the same call is another defect and gets its own.
  # The message is part of the kind because every failure of sendmail is
  # one class, told apart by its exit status; the recipient, masked, is
  # not. It is not held until the end of the
  # call: with the mail server down every message waits for its timeout, and
  # a process killed before the end would report nothing. The server log has
  # a line for each message (report_failure).
  #
  # The failure goes without the addresses in its message, nor the
  # recipients of sendmail, the delivery of production, which fails with
  # the whole command. The exception keeps its class and backtrace; the
  # recipient stays in the server log (report_failure).
  def self.notify_failure(error, message, delivered:)
    ExceptionNotifier.notify_exception(
      without_addresses(error),
      data: { notification_id: message[:notification_id], delivered: delivered, note: FAILURE_NOTE }
    )
  end

  # What the error email cannot tell by itself: being one per kind of
  # failure, it may stand for more messages than the one it names. Fixed, and
  # not a count: the email goes at the first failure, before the call knows
  # how many will follow.
  FAILURE_NOTE = "Outras mensagens deste envio podem ter falhado pelo mesmo motivo sem gerar outro " \
    "e-mail de erro; o log do servidor tem uma linha por mensagem."

  # Anything shaped like an address: no quote, bracket, comma or space
  # around an @. Loose on purpose, as it masks rather than validates.
  ADDRESS = /[^\s"'<>()\[\],;:]+@[^\s"'<>()\[\],;:]+/

  # The recipients of the sendmail command, after its "--": each one goes as
  # the template rendered it, and one that is not an address (a name where
  # the address goes) would get past ADDRESS.
  SENDMAIL_RECIPIENTS = /(?<="--", ).*(?=\]\z)/

  def self.without_addresses(error)
    masked = error.message.sub(SENDMAIL_RECIPIENTS, '"<recipients>"').gsub(ADDRESS, "<address>")
    return error if masked == error.message

    error.exception(masked)
  end

  # What the server log keeps of a delivered message: who was notified and
  # about what. The body is written for the recipient alone, and its place is
  # the NotificationLog, which is read behind the permissions of the
  # application; the server log is read by whoever operates the machine and
  # is copied to rotated files and backups.
  def self.display_notification_info(notification, attachments_file_name_list)
    Notifier.logger.info "\n#{Time.current.strftime("%Y/%m/%d %H:%M:%S")}"
    Notifier.logger.info "########## Notification ##########"
    Notifier.logger.info "Notifying: #{notification[:to]}"
    Notifier.logger.info "Replying: #{notification[:reply_to]}"
    Notifier.logger.info "Subject: #{notification[:subject]}"
    if attachments_file_name_list
      Notifier.logger.info "Attachments: #{attachments_file_name_list}"
    end
    Notifier.logger.info "##################################"
  end
end
