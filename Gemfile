# ruby=3.2.5
# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# The following line is necessary to allow RVM choosing the correct ruby version. RVM 2.0 will probably be able to interpret the "~>" symbol and we will be able to safely remove the "#ruby=3.2.2" line.
ruby "~> 3.2.5"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2.1"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use sqlite3 as the database for Active Record
# gem "sqlite3", "~> 1.4"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 6.4.2"

# HTML and XML parser
gem "nokogiri", ">= 1.16.5"

# Wrapp HTTP requests and responses
gem "rack", ">= 2.2.8.1"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
# gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
# gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
# gem "stimulus-rails"

# Use Terser as compressor for JavaScript assets
# gem "terser"
# gem "mini_racer"

# Use CoffeeScript for .js.coffee assets and views
gem "coffee-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use jquery as the JavaScript library
gem "jquery-rails"
gem "jquery-ui-rails", git: "https://github.com/jquery-ui-rails/jquery-ui-rails.git", tag: "v7.0.0"

# Pagination
gem "kaminari"

# User access
gem "cancancan"
gem "devise", "~> 4.9"
gem "devise_invitable", "~> 2.0.0"
gem "paper_trail"

# Use Active record session store
gem "activerecord-session_store"

# Iconography
gem "font-awesome-rails"

# Prawn to PDF
gem "prawn"
gem "prawn-table"
gem "prawn-rails"
gem "matrix", "~> 0.4.2"
gem "prawn-qrcode"

# Redcarpet for Readme MarkDown (or README.md) - Credits Page
gem "redcarpet"

# Active scaffold support for newer Rails
gem "active_scaffold", git: "https://github.com/activescaffold/active_scaffold.git", ref: "7a61ff721e4ee68ac9dc5ce65128f63b067a4d7d"
gem "active_scaffold_duplicate", ">= 1.1.0"
gem "recordselect"

# Date Validation Plugin
gem "validates_timeliness", "~> 7.0.0.beta1"

# Menu
gem "simple-navigation"

# Notification
gem "rufus-scheduler"

# Image
gem "carrierwave", ">= 3.0.7"
gem "carrierwave-activerecord", git: "https://github.com/gems-uff/carrierwave-activerecord.git", branch: "rails7"

# Nested Forms / ApplicationProcess and FormTemplates functionalities.
gem "cocoon"

# ReCaptcha Helpers
gem "dotenv-rails", require: "dotenv/load"
gem "recaptcha", require: "recaptcha/rails"

# xlsx Spreadsheets
gem "rubyzip"
gem "caxlsx"
gem "caxlsx_rails"
# gem "acts_as_xlsx"

# Temporary fix of warnings
# In the beggining of rails command executions, it shows some warnings related to these gems
# If I'm not mistaken, the warnings should disappear on Ruby 3 or when a gem that depends on these gems update (I don't know which)
# So, try to remove these gems from this file in the future and check if the warnings appear.
gem "net-http"
gem "net-smtp"
gem "net-imap"


group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # Linter
  gem "rubocop", require: false
  gem "rubocop-rails_config", require: false
end

group :development, :test do
  # Use SQLite database for development
  gem "sqlite3", "~> 1.6.8"

  # Prints Ruby object in full color
  gem "awesome_print"

  # View a better error page
  gem "binding_of_caller"
  gem "better_errors"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]

  # Better console for debugging
  gem "pry"

  # Open /letter_opener in the browser to view 'sent' emails
  gem "letter_opener_web"

  # Create entity-relationship diagram
  gem "rails-erd"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Test runner
  gem "rspec-rails"

  # Fixtures replacement
  gem "factory_bot_rails"

  # Suport 'have' syntax of rspec
  gem "rspec-collection_matchers"

  # Simpler specs
  gem "shoulda-matchers"

  # Clean database for every test
  gem "database_cleaner-active_record"

  # Measure code coverage
  gem "simplecov"
end

# Notify exceptions
gem "exception_notification"
group :production do
  # Use MySQL database for production
  gem "mysql2"

  # Temporary fix for passenger
  gem "stringio"
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem "rdoc", ">= 6.5.1.1"
  gem "sdoc", require: false
end
