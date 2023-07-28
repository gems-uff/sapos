source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# The following line is necessary to allow RVM choosing the correct ruby version. RVM 2.0 will probably be able to interpret the "~>" symbol and we will be able to safely remove the "#ruby=2.7.1" line.
#ruby=2.7.1
ruby '~> 2.7.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1', '>= 6.1.7.4'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3', '~> 1.4'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem 'webpacker', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false


# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Pagination
gem "kaminari"

# User access
gem 'cancancan'
gem "devise", "~> 4.9"
gem 'devise_invitable', '~> 2.0.0'
gem "paper_trail"

# Use Active record session store
gem 'activerecord-session_store'

# Iconography
gem 'font-awesome-rails'

# Prawn to PDF
gem 'prawn'
gem 'prawn-table' 
gem 'prawn-rails'

# Redcarpet for Readme MarkDown (or README.md) - Credits Page
gem 'redcarpet' 

# Active scaffold support for Rails 3
gem 'active_scaffold', :git => 'https://github.com/activescaffold/active_scaffold.git'
gem 'active_scaffold_duplicate', '>= 1.1.0'
gem 'recordselect'

#Date Validation Plugin
gem 'validates_timeliness'

# Menu
gem 'simple-navigation'

# Notification
gem 'rufus-scheduler'

# Image
gem 'carrierwave'
gem 'carrierwave-activerecord', :git => 'https://github.com/gems-uff/carrierwave-activerecord.git', :branch => 'rails61'


group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  # Linter
  gem 'rubocop', require: false
end

group :development, :test do

gem 'rspec-rails'

# Use SQLite database for development
  gem 'sqlite3'

  # Prints Ruby object in full color
  gem 'awesome_print'

  # View a better error page
  gem 'binding_of_caller'
  gem 'better_errors'
  
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  # Open /letter_opener in the browser to view 'sent' emails
  gem 'letter_opener_web'

  # Create entity-relationship diagram
  gem "rails-erd"
end

group :test do
  # Test runner
#  gem 'rspec-rails'

  # Fixtures replacement
  gem 'factory_bot_rails'
  
  # Suport 'have' syntax of rspec
  gem 'rspec-collection_matchers'

  # Simpler specs
  gem 'shoulda-matchers'

  # Clean database for every test
  gem 'database_cleaner-active_record'

  # Measure code coverage
  gem 'simplecov'
end

# Notify exceptions
gem 'exception_notification'
group :production do
  # Use MySQL database for production
  gem 'mysql2'
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'rdoc'
  gem 'sdoc', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]