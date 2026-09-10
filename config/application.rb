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
    # A subida de 8.0 para 8.1 mexe em sete coisas; a varredura do codigo mostra
    # que nenhuma quebra algo aqui:
    #   - active_record.raise_on_missing_required_finder_order_columns = true: so
    #     levanta erro quando o modelo nao tem primary_key, implicit_order_column
    #     nem query_constraints; toda tabela daqui e id-keyed, entao nao pega
    #     ninguem.
    #   - action_controller.action_on_path_relative_redirect = :raise: so pega
    #     redirect_to com String que nao comeca por "/" nem por "?"; os redirects
    #     daqui usam helper de rota, hash ou objeto de modelo, e o mesmo vale para
    #     o active_scaffold e o record_select.
    #   - action_controller.escape_json_responses = false: desliga o escape no
    #     renderer de `render json:`, e o faz SOBREPONDO o
    #     escape_html_entities_in_json -- injeta `escape: false` no to_json --,
    #     nao de forma independente dele. Os nove `render json:` daqui passam de
    #     fato a emitir `<` cru. O que mantem isso inocuo e que todos sao
    #     consumidos por AJAX com `dataType: "json"`, onde o JSON.parse desfaz o
    #     escape de qualquer modo: ele nunca protegeu esse caminho. Quem depende
    #     do escape e o `to_json` interpolado em HTML nas views, e esse continua
    #     regido pelo escape_html_entities_in_json = true (abaixo), que este flag
    #     nao toca. O caminho JSONP (`options[:callback]`) tambem segue escapando.
    #   - active_support.escape_js_separators_in_json = false: este SIM alcanca o
    #     `to_json` das views. Medido: com escape_html_entities_in_json = true o
    #     encoder passa a usar so o HTML_ENTITIES_REGEX, entao `<>&` seguem
    #     escapados mas U+2028/U+2029 saem crus. Inocuo porque os dois sao
    #     caracteres validos em literal de string desde o ES2019 -- e nao porque
    #     o flag nao tenha efeito.
    #   - action_view.render_tracker = :ruby: troca o rastreador de dependencia
    #     entre templates. Ele alimenta o ActionView::Digestor, que roda onde se
    #     calcula digest de template, e producao tem perform_caching = true --
    #     logo nao e "so desenvolvimento". E inerte aqui por outro motivo: nada no
    #     projeto usa o helper `cache`, nem fresh_when/stale?/etag.
    #   - action_view.remove_hidden_field_autocomplete = true: tira
    #     autocomplete="off" de nove sitios do actionview, e nao so do
    #     hidden_field -- entram o `authenticity_token` (url_helper#token_tag), o
    #     `_method` de override (#method_tag), os campos de parametro do
    #     button_to, o hidden que acompanha check_box, o do select multiple e o do
    #     file_field. (O enforcer `utf8` tambem esta na lista do Rails, mas aqui
    #     nao sai: default_enforce_utf8 e false desde o load_defaults 6.0.)
    #
    #     O Rails removeu o atributo por validade de HTML: `autocomplete` nao e
    #     valido em input hidden, entao o framework emitia HTML invalido. Nao foi
    #     por seguranca nem por desempenho.
    #
    #     Duas consequencias aqui. Uma e de diff: muda o HTML de praticamente toda
    #     tela com formulario, logo e diferenca ESPERADA numa comparacao de
    #     homologacao, nao regressao. A outra e que o atributo entrou em 2021 como
    #     contorno de um bug do Firefox que sobrescrevia o PRIMEIRO campo hidden
    #     da forma -- e aqui o primeiro e justamente o `_method` ou o
    #     `authenticity_token`. O PR do Rails que removeu o atributo nao afirma que
    #     o bug foi corrigido. Se ele ocorrer, token trocado com sessao viva cai no
    #     ramo de anomalia do ApplicationController#expired_session, que notifica
    #     por e-mail. Para voltar ao comportamento antigo basta
    #     `config.action_view.remove_hidden_field_autocomplete = false`.
    #   - yjit passa de true (herdado do bloco 7.2) para `!Rails.env.local?`,
    #     deixando de ligar em desenvolvimento e teste. Inocuo aqui porque o Ruby
    #     em uso nao tem YJIT compilado (`defined?(RubyVM::YJIT)` devolve nil) e o
    #     initializer ainda guarda com `defined?(RubyVM::YJIT.enable)`. Num Ruby
    #     com YJIT, o efeito seria apenas desliga-lo fora de producao.
    config.load_defaults 8.1

    # ActiveScaffold defines callbacks for actions not always present in all controllers.
    # Rails 7.1 raised this to true by default, causing AbstractController::ActionNotFound.
    config.action_controller.raise_on_missing_callback_actions = false

    # O patch de seguranca CVE-2026-66066 (Rails 8.1.3.1) faz o Active Storage
    # resolver o variant transformer ja no boot, no after_initialize, para
    # bloquear os loaders nao confiaveis do libvips. Com o default :vips isso
    # carrega o ActiveStorage::Transformers::Vips, que requer
    # `image_processing/vips` e, por tabela, o gem ruby-vips -- ausente do lock de
    # todo ambiente.
    #
    # O engine tenta degradar biblioteca de imagem ausente para um logger.warn,
    # mas o rescue so reconhece mensagem casando /libvips/ ou /image_processing/.
    # A que ruby-vips ausente produz e "ImageProcessing::Vips requires the
    # ruby-vips gem", que nao casa com nenhuma das duas: cai no `else` e levanta.
    # Sem a linha abaixo o boot morre com LoadError em qualquer ambiente --
    # producao inclusive, e nao so em desenvolvimento e CI.
    #
    # O SAPOS nao usa variantes do Active Storage: o upload e via carrierwave, que
    # puxa o image_processing so por transitividade, e nao ha anexo nem tabela
    # active_storage no esquema. Entao :disabled -- o valor que a propria mensagem
    # do Rails sugere -- seleciona o NullTransformer, que nao carrega gem de imagem
    # nenhum. Sem efeito funcional.
    config.active_storage.variant_processor = :disabled

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
