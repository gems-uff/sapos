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

    messages = notifications[:notifications]
    messages_attachments = notifications[:notifications_attachments] || {}

    messages.each do |message|
      options = {}
      m = message.merge(options)
      next if m[:skip_message]
      m_attachments = messages_attachments[message]
      if !CustomVariable.notification_footer.empty? && ! m[:skip_footer]
        # a footer is written as text in a custom variable, and a body is
        # markup, so the footer is escaped on its way into the body
        m[:body] += "\n\n\n" + Notifier.as_markup(CustomVariable.notification_footer)
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
      unless m[:to].blank?
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
        Notifier.display_notification_info(m, attachments_file_name_list)
      end
    end
  end

  def self.display_notification_info(notification, attachments_file_name_list)
    Notifier.logger.info "\n#{Time.now.strftime("%Y/%m/%d %H:%M:%S")}"
    Notifier.logger.info "########## Notification ##########"
    Notifier.logger.info "Notifying: #{notification[:to]}"
    Notifier.logger.info "Replying: #{notification[:reply_to]}"
    Notifier.logger.info "Subject: #{notification[:subject]}"
    Notifier.logger.info "body: #{notification[:body]}"
    if attachments_file_name_list
      Notifier.logger.info "Attachments: #{attachments_file_name_list}"
    end
    Notifier.logger.info "##################################"
  end
end
