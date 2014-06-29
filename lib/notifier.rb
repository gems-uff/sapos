# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'singleton'

module Notifier

  def self.logger
    Rails.logger
  end
  
  def self.should_run?
    Rails.application.config.should_send_emails
  end

  def self.run_notifications
    Notifier.logger.info "[Notifications] #{Time.now} - Notifications from DB"
    notifications = []

    #Get the next execution time arel table
    next_execution = Notification.arel_table[:next_execution]

    #Find notifications that should run
    Notification.where(next_execution.lt(Time.now)).each do |notification|
      notifications += notification.execute
    end
    notifications
  end

  def self.asynchronous_emails
    Notifier.logger.info "Sending Registered Notifications"
    Notifier.send_emails(Notifier.run_notifications)
  end

  def self.send_emails(notifications)
    Notifier.logger.info "Starting send_emails function."
    unless Notifier.should_run?
      Notifier.logger.info "Execution method is not 'Server'. Stoping process."
      return
    end

    if CustomVariable.redirect_email == ''
      Notifier.logger.info "Custom Variable 'redirect_email' is empty. Stoping process."
      return
    end

    messages = notifications[:notifications]

    messages.each do |message|
      options = {}
      m = message.merge(options)
      unless CustomVariable.notification_footer.empty?
        m[:body] += "\n\n\n" + CustomVariable.notification_footer
      end
      unless CustomVariable.redirect_email.nil?
        Notifier.logger.info "Custom Variable 'redirect_email' is set. Redirecting the emails"
        m[:body] = "Originalmente para #{m[:to]}\n\n" + m[:body]
        m[:to] = CustomVariable.redirect_email
      end
      unless m[:to].nil? or m[:to].empty?
        ActionMailer::Base.mail(m).deliver!
        NotificationLog.new(
          :notification_id => m[:notification_id], 
          :to => m[:to], 
          :subject => m[:subject],
          :body => m[:body]
        ).save
        Notifier.display_notification_info(m)
      end
    end
  end

  def self.display_notification_info(notification)
    Notifier.logger.info "\n#{Time.now.strftime('%Y/%m/%d %H:%M:%S')}"
    Notifier.logger.info "########## Notification ##########"
    Notifier.logger.info "Notifying #{notification[:to]}"
    Notifier.logger.info "Subject: #{notification[:subject]}"
    Notifier.logger.info "body: #{notification[:body]}"
    Notifier.logger.info "##################################"
  end
end
