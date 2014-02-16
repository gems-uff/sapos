# coding: utf-8

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require './lib/notifier'

notifier = Notifier.instance

notifier.new_notification do
  Rails.logger.info "[Notifications] #{Time.now} - Notifications from DB"
  notifications = []

  #Get the next execution time arel table
  next_execution = Notification.arel_table[:next_execution]

  #Find notifications that should run
  Notification.where(next_execution.lt(Time.now)).each do |notification|
    notifications += notification.execute
  end
  notifications
end
