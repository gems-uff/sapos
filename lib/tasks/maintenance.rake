# frozen_string_literal: true

namespace :maintenance do
  desc "Runs every maintenance task needed"
  task run: [:environment] do
    Rails.logger.info "[Maintenance] #{Time.now.to_fs} - Starting maintenance tasks"
    Rake::Task["maintenance:remove_expired_reports"].invoke
    Rake::Task["maintenance:trigger_notifications"].invoke
    Rails.logger.info "[Maintenance] #{Time.now.to_fs} - Finished maintenance tasks"
  end

  task remove_expired_reports: [:environment] do
    Rails.logger.info "[Reports] #{Time.now.to_fs} Removing expired reports from DB"
    expired_reports = Report.where(expires_at: ...Date.today).where.not(carrierwave_file_id: nil)

    expired_reports.map do |expired_report|
      carrierwave_file = expired_report.carrierwave_file
      expired_report.update!(carrierwave_file_id: nil)
      carrierwave_file.delete
    end

    Rails.logger.info "[Reports] #{Time.now.to_fs} Finished removing reports"
  end

  task trigger_notifications: [:environment] do
    Notifier.logger.info "Sending Registered Notifications"

    Notifier.logger.info "[Notifications] #{Time.now.to_fs} - Notifications from DB"
    notifications = []
    notifications_attachments = {}

    # Get the next execution time arel table
    next_execution = Notification.arel_table[:next_execution]

    # Find notifications that should run
    Notification.where.not(frequency: Notification::MANUAL)
                .where(next_execution.lt(Time.now)).each do |notification|
      result = prepare_attachments(notification.execute)
      notifications.concat(result[:notifications])
      notifications_attachments.merge!(result[:notifications_attachments])
    end

    Notifier.send_emails({
                           notifications: notifications,
                           notifications_attachments: notifications_attachments
                         })

    Notifier.logger.info "[Notifications] #{Time.now.to_fs} - Finished sending notifications"
  end
end
