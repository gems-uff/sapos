# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Debug assets
  config.assets.debug = true
  config.assets.compile = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Allow the notifier to send emails
  config.should_send_emails = Rails.const_defined?("Server")

  # Use ReCaptcha
  config.should_use_recaptcha = false

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false
  config.public_file_server.enabled = false

  # Configure ActionMailer
  config.action_mailer.default_url_options = { host: "localhost:3000" }
  # config.action_mailer.delivery_method = :sendmail
  # config.action_mailer.sendmail_settings = {location: "/usr/sbin/sendmail" }

  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false

  # config.action_mailer.smtp_settings = {
  #     address:              "smtp.gmail.com",
  #     port:                 587,
  #     domain:               "gmail.com",
  #     user_name:            "everton.moreth@gmail.com",
  #     password:             "gjoao.pe,feijao!O",
  #     authentication:       "plain",
  #     enable_starttls_auto: true
  # }

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  config.middleware.use ExceptionNotification::Rack,
    email: {
      email_prefix: "[SAPOS: Error] ",
      sender_address: %{"SAPOS Exception Notifier" <erro-sapos@sapos.ic.uff.br>},
      exception_recipients: %w{letter@saposletteropener.com}
    }
end
