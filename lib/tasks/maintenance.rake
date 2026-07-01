# frozen_string_literal: true

namespace :maintenance do
  desc "Runs every maintenance task needed"
  task run: [:environment] do
    Rails.logger.info "[Maintenance] #{Time.now.to_fs} - Starting maintenance tasks"
    Rake::Task["maintenance:remove_expired_reports"].invoke
    Rake::Task["maintenance:clean_upload_cache"].invoke
    Rake::Task["maintenance:trigger_notifications"].invoke
    Rails.logger.info "[Maintenance] #{Time.now.to_fs} - Finished maintenance tasks"
  end

  desc "Removes stale CarrierWave upload cache (default: older than 24h)"
  task clean_upload_cache: [:environment] do
    Rails.logger.info "[UploadCache] #{Time.now.to_fs} - Cleaning stale CarrierWave cache"
    # The uploaders set config.root = Rails.root, so the file cache lives in
    # Rails.root/uploads/tmp. CarrierWave.clean_cached_files! would use the base
    # uploader (root = public/) and scan the wrong directory, so we clean from the
    # actual uploader classes. clean_cached_files! only removes cache entries older
    # than the threshold (default 24h), never touching DB blobs or stored uploads.
    # The maintenance cron runs daily, so 24h is a safe margin for ongoing uploads.
    [FormFileUploader, ImageUploader].each(&:clean_cached_files!)
    Rails.logger.info "[UploadCache] #{Time.now.to_fs} - Finished cleaning cache"
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

  private
    def prepare_attachments(notification_result)
      include SharedPdfConcern
      include AbstractController::Rendering
      notification_result[:notifications].each do |message|
        attachments = notification_result[:notifications_attachments][message]
        next if attachments.blank?
        if attachments[:grades_report_pdf]
          enrollment = Enrollment.find(message[:enrollments_id])
          attachments[:grades_report_pdf][:file_contents] =
            render_enrollments_grades_report_pdf(enrollment)
        end
      end
      notification_result
    end
end
