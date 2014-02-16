# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'singleton'

class Notifier
  include Singleton

  def initialize
    @async_notifications = []
    @logger = Rails.logger
    @job = nil
    
    return unless should_run?

    @scheduler = Rufus::Scheduler.new
    start_job(Rails.env.development? || Rails.env.test?)    
  end

  def start_job(development)
    @job.unschedule unless @job.nil?
    
    if development
      first_at = Time.now + 1.second
    else
      first_at = Time.parse(CustomVariable.notification_start_at)
      if first_at < Time.now
        first_at += 1.day
      end
    end
    @logger.info "[Notifications] #{Time.now} - Scheduling next execution to #{first_at}"
    @job = @scheduler.schedule_every CustomVariable.notification_frequency, :first_at => first_at do
      @logger.info "[Notifications] #{Time.now} - Running notifications"
      asynchronous_emails
    end
  end

  def should_run?
    Rails.application.config.should_send_emails
  end

  def job
    @job
  end

  def new_notification(&block)
    @async_notifications << lambda { yield }
  end

  def notifications
    @async_notifications
  end

  def run_notifications
    @async_notifications.map{ |n| n.call }.flatten
  end

  def asynchronous_emails
    send_emails(run_notifications)
  end

  def send_emails(messages)
    @logger.info "Starting send_emails function."
    unless should_run?
      @logger.info "Execution method is not 'Server'. Stoping process."
      return
    end

    if CustomVariable.redirect_email == ''
      @logger.info "Custom Variable 'redirect_email' is empty. Stoping process."
      return
    end
    
    messages.each do |message|
      options = {}
      m = message.merge(options)
      unless CustomVariable.notification_footer.empty?
        m[:body] += "\n\n\n" + CustomVariable.notification_footer
      end
      unless CustomVariable.redirect_email.nil?
        @logger.info "Custom Variable 'redirect_email' is set. Redirecting the emails"
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
        ).save unless m[:notification_id].nil?
        display_notification_info(m)
      end
    end
  end

  def display_notification_info(notification)
    @logger.info "\n#{Time.now.strftime('%Y/%m/%d %H:%M:%S')}"
    @logger.info "########## Notification ##########"
    @logger.info "Notifying #{notification[:to]}"
    @logger.info "Subject: #{notification[:subject]}"
    @logger.info "body: #{notification[:body]}"
    @logger.info "##################################"
  end
end
