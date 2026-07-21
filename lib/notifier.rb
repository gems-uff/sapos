# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "singleton"

module Notifier
  # Number of spaces that replaces a tab when converting a body to HTML
  TAB_WIDTH = 8

  # Markup that the toolbar of the template editor produces in a body: the
  # bold and italic buttons write the tags, and the align tag of
  # lib/liquid_formatter.rb renders the div.
  TOOLBAR_MARKUP = %r{
    </?strong> | </?em> | </div> |
    <div\s+style=["']text-align:\s*(?:left|center|right|justify);\s*["']>
  }x

  def self.logger
    Rails.logger
  end

  # Escapes a message body, keeping the markup of the template editor toolbar.
  #
  # Templates are filled with data that the user did not write and that is not
  # meant to be read as markup. An address such as "Fulano <fulano@uff.br>"
  # would be swallowed by the mail client, so everything is escaped and only
  # the markup that the toolbar produces is given back.
  def self.escape_body(body)
    text = body.to_s
    result = +""
    open_divs = 0
    last = 0
    text.scan(TOOLBAR_MARKUP) do
      match = Regexp.last_match
      result << ERB::Util.html_escape(text[last...match.begin(0)])
      markup = match[0]
      if markup == "</div>"
        # a closing tag is only markup when the align tag opened a div
        if open_divs.positive?
          open_divs -= 1
          result << markup
        else
          result << ERB::Util.html_escape(markup)
        end
      else
        open_divs += 1 if markup.start_with?("<div")
        result << markup
      end
      last = match.end(0)
    end
    result << ERB::Util.html_escape(text[last..])
    result
  end

  # Builds the text part of a message, removing the markup of the toolbar.
  #
  # The body is written as text, so it is used as it is. Only the markup that
  # the toolbar produces is removed, because it has no meaning when read as
  # text.
  def self.plain_body(body)
    body.to_s.gsub(TOOLBAR_MARKUP, "")
  end

  # Converts the whitespace of a message body into its HTML equivalent.
  #
  # Notification and email templates are written as text, but the toolbar of
  # the template editor also produces inline markup (<strong>, <em> and the
  # <div> of the align tag), so the body is delivered as HTML as well. HTML
  # collapses every run of whitespace, which would join all the lines of the
  # body into a single paragraph. Line breaks become <br> and the indentation
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
        m[:body] += "\n\n\n" + CustomVariable.notification_footer
      end
      if !CustomVariable.redirect_email.nil? && ! m[:skip_redirect]
        Notifier.logger.info "Custom Variable 'redirect_email' is set. Redirecting the emails"
        m[:body] = "Originalmente para #{m[:to]}\n\n" + m[:body]
        m[:to] = CustomVariable.redirect_email
      end
      unless CustomVariable.reply_to.nil?
        Notifier.logger.info "Custom Variable 'reply_to' is set. Forwarding email"
        m[:reply_to] = CustomVariable.reply_to
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
          plain = m[:body_text] || Notifier.plain_body(m[:body])
          format.text { plain }
          format.html do
            Notifier.body_whitespace_to_html(
              Notifier.escape_body(m[:body])
            ).html_safe
          end
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
