# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "singleton"

module Notifier
  def self.logger
    Rails.logger
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

        actionmailer_base.mail(m).deliver!

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
    Notifier.logger.info "Notifying #{notification[:to]}"
    Notifier.logger.info "Replying #{notification[:reply_to]}"
    Notifier.logger.info "Subject: #{notification[:subject]}"
    Notifier.logger.info "body: #{notification[:body]}"
    if attachments_file_name_list
      Notifier.logger.info "Attachments: #{attachments_file_name_list}"
    end
    Notifier.logger.info "##################################"
  end
end
