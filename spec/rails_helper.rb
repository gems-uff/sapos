# This file is copied to spec/ when you run "rails generate rspec:install"

# frozen_string_literal: true

require "spec_helper"

require "simplecov"
SimpleCov.start "rails" do
  #enable_coverage_for_eval
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!
require "rspec/collection_matchers"

require "capybara/rails"
require "capybara/rspec"

require "support/date_helpers"
require "support/user_helpers"
require "support/place_widgets_helpers"
require "support/record_select_helpers"
require "support/download_helpers"

Capybara.server = :puma


# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/6-0/rspec-rails
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  Capybara.register_driver :selenium do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile["devtools.selfxss.count"] = 9999
    profile["browser.download.dir"] = DownloadHelpers::PATH.to_s
    profile["browser.download.folderList"] = 2

    # Suppress "open with" dialog
    profile["browser.helperApps.neverAsk.saveToDisk"] =
      "text/csv,text/tsv,text/xml,text/plain,application/pdf,application/doc,application/docx,image/jpeg,application/gzip,application/x-gzip"
    options = Selenium::WebDriver::Firefox::Options.new
    options.profile = profile
    Capybara::Selenium::Driver.new(
      app,
      browser: :firefox,
      options: options
    )
  end

  config.include DateHelpers
  config.include UserHelpers
  config.include PlaceWidgetsHelpers
  config.include RecordSelectHelpers
  config.include DownloadHelpers
  config.include Warden::Test::Helpers

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DownloadHelpers.clear_downloads
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.after(:suite) do
    models = ApplicationRecord.descendants
    leaked = models.filter_map do |model|
      "#{model}: #{model.count}" if model.count > 0
    end
    if leaked.count > 0
      puts "Leaked objects -- Please, try to find and delete them to avoid one test interfering with the other"
      puts "  #{leaked.join("\n  ")}"
    end
  end
end


Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
