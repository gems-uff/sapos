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
      result = attachment_renderer.prepare_attachments(notification.execute)
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
    # The class is built on first use, not at the top level of this file: rake
    # loads every rakefile before running any task, so a top-level body would
    # resolve SharedPdfConcern before the environment is loaded, and Zeitwerk
    # cannot autoload it yet. That raises NameError on *every* rake invocation,
    # not just on this task.
    #
    # ApplicationController.renderer runs render_to_string inside a real
    # controller context -- the view context that SharedPdfConcern requires and
    # that AbstractController::Rendering did not provide (#632: render_to_string
    # returned nil and the attachment came out empty). A cron process has no
    # warden, so Devise's current_user would raise; rendering as a guest
    # (current_user = nil) makes can? return false and leaves signature override
    # as nil, which is the correct behaviour. clear_helpers requires declaring
    # the same PDF helpers as the web path, otherwise new_document and friends
    # are undefined in the view.
    def attachment_renderer
      @attachment_renderer ||= begin
        guest = Class.new(ApplicationController) do
          helper PdfHelper
          helper EnrollmentsPdfHelper
          def current_user = nil
          # The template guards the signature_type override behind
          # can?(:override_report_signature_type). Without a real user CanCan
          # would deny it, leaving the default QR-code config active and
          # causing Report.create!(user: nil) to fail the "Gerado por" validation.
          # Granting only this one action is safe: the renderer is never exposed
          # to web requests and current_user is nil (no persisted Report is
          # created for the cron-generated PDF).
          def can?(action, *) = action == :override_report_signature_type
          def cannot?(action, *) = action != :override_report_signature_type
        end
        renderer = guest.renderer
        Class.new do
          include SharedPdfConcern
          define_method(:render_to_string) do |*args, **kwargs|
            renderer.render(*args, **kwargs)
          end
        end.new
      end
    end
end
