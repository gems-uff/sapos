# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'singleton'

class Notifier
  include Singleton

  def initialize
    @notifications = []
    @options = {}

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
      send_emails
    end
  end

  def new_notification(&block)
    @notifications << lambda { yield }
  end

  def notifications
    @notifications
  end

  def run_notifications
    result = []
    @notifications.each do |notification|
      result += notification.call
    end
    result
  end

  def send_emails
    run_notifications.each do |message|
      m = message.merge(@options)
      ActionMailer::Base.mail(m).deliver!
      display_notification_info(m)
    end
  end

  def display_notification_info(notification)
    puts "\n#{Time.now.strftime('%Y/%m/%d %H:%M:%S')}"
    puts "########## Notification ##########"
    puts "Notifying #{notification[:to]}"
    puts "Subject: #{notification[:subject]}"
    puts "body: #{notification[:body]}"
    puts "##################################"
  end
end

