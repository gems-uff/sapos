# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# O active_scaffold 4.3 registra o initializer 'active_scaffold.testing', que
# chama RSpec.configure ao subir o app sempre que defined?(RSpec) (engine.rb). O
# guard é frouxo: num boot que não passa pelo binário do rspec -- rake, console,
# assets:precompile em RAILS_ENV=test -- o Bundler.require acima carrega o grupo
# :test e define o módulo RSpec, mas RSpec.configure (do rspec-core) só existe
# quando o rspec-core é carregado, e o binário do rspec é quem o carrega primeiro.
# Sem ele o initialize! estoura com NoMethodError e derruba db:schema:load,
# db:migrate e afins (foi o que quebrou o CI, #621). Carregar o rspec-core quando
# o grupo :test está ativo garante o método antes de qualquer engine initializer.
# Em produção o grupo :test não entra, a condição é falsa, e nada disso carrega.
require "rspec/core" if Rails.env.test?

module Sapos
  class Application < Rails::Application
    # Defaults versionados do framework:
    #   https://guides.rubyonrails.org/configuring.html#versioned-default-values
    #
    # Das seis flags que a subida de 7.1 para 8.0 mexe, uma so muda algo aqui:
    # Regexp.timeout = 1s. As outras cinco sao inocuas neste projeto -- o commit
    # que fez a subida registra a verificacao de cada uma. A que merece nota por
    # depender do ambiente e o yjit: nem o Ruby de desenvolvimento nem o de
    # producao tem YJIT compilado (`defined?(RubyVM::YJIT)` devolve nil nos dois),
    # entao ligar a flag nao liga JIT nenhum. Num Ruby com YJIT, ligaria.
    config.load_defaults 8.0

    # ActiveScaffold defines callbacks for actions not always present in all controllers.
    # Rails 7.1 raised this to true by default, causing AbstractController::ActionNotFound.
    config.action_controller.raise_on_missing_callback_actions = false


    # Allow the notifier to send emails
    config.should_send_emails = false

    # config.action_controller.permit_all_parameters = true
    # config.action_controller.action_on_unpermitted_parameters = :raise

    config.eager_load_paths << Rails.root.join("lib")
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths << "#{config.root}/lib"


    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
    config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "Brasilia"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join("my", "locales", "*.{rb,yml}").to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false
    config.i18n.default_locale = "pt-BR"

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = "1.0"
  end

  ActionMailer::Base.default from: "SAPOS <sapos@sapos.ic.uff.br>"
end
