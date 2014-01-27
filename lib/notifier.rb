# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'singleton'

class Notifier
  include Singleton

  def initialize
    @async_notifications = []
    @options = {}
    @logger = Rails.logger
    
    return unless Rails.const_defined? 'Server'

    if Rails.env.development? or Rails.env.test? 
      @options = {:to => 'sapos@mailinator.com'}
      first_at = Time.now + 1.second
    else
      first_at = Time.parse(Configuration.notification_start_at)
      if first_at < Time.now
        first_at += 1.day
      end
    end

    scheduler = Rufus::Scheduler.new
    scheduler.every Configuration.notification_frequency, :first_at => first_at do
      asynchronous_emails
    end
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
    messages.each do |message|
      m = message.merge(@options)
      unless m[:to].nil? or m[:to].empty?
        ActionMailer::Base.mail(m).deliver!
        NotificationLog.new(
          :notification_id => m[:notification_id], 
          :to => m[:to], 
          :subject => m[:subject],
          :body => m[:body]
        ).save
        display_notification_info(m)
      end
    end
  end

  #ToDo: Use rails logger
  def display_notification_info(notification)
    @logger.info "\n#{Time.now.strftime('%Y/%m/%d %H:%M:%S')}"
    @logger.info "########## Notification ##########"
    @logger.info "Notifying #{notification[:to]}"
    @logger.info "Subject: #{notification[:subject]}"
    @logger.info "body: #{notification[:body]}"
    @logger.info "##################################"
  end
end
