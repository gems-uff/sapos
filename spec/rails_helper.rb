# This file is copied to spec/ when you run "rails generate rspec:install"

# frozen_string_literal: true

require "spec_helper"

require "simplecov"
require "simplecov-cobertura"
SimpleCov.start "rails" do
  # enable_coverage_for_eval
  formatter SimpleCov::Formatter::CoberturaFormatter
end unless ENV["SKIP_COVERAGE"]

ENV["RAILS_ENV"] ||= "test"

# Antes do boot: depois dele o manifesto de assets ja esta em memoria, e
# recompilar nao mudaria o que esta rodada serve ao navegador.
require_relative "support/asset_freshness"
AssetFreshness.recompile_if_stale!

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
require "support/uniqueness_examples"

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

# Modelos que ficaram com registro, para os detectores de vazamento.
#
# Varre ActiveRecord::Base, nao ApplicationRecord: os modelos de Admissions
# herdam direto de ActiveRecord::Base e ficavam invisiveis. Sao 62 descendentes
# de ApplicationRecord contra 104 de ActiveRecord::Base -- 42 modelos fora do
# alcance do detector, incluindo exatamente onde estava o vazamento da #643.
#
# eager_load! porque config.eager_load so e ligado no CI: sem ele, descendants
# devolve apenas o que ja foi carregado -- uma classe, na maquina local.
module LeakDetector
  def self.counts
    Rails.application.eager_load!
    ActiveRecord::Base.descendants.each_with_object({}) do |model, acc|
      next if model.abstract_class? || model.name.nil?
      next if model.name.start_with?("ActiveRecord::")  # tabelas de controle
      begin
        next unless model.table_exists?
        count = model.count
      rescue StandardError
        next
      end
      acc[model.name] = count if count > 0
    end
  end

  def self.leaked_records
    counts.map { |name, count| "#{name}=#{count}" }.sort
  end

  # Apaga o que sobrou, ao fim de um grupo de topo.
  #
  # Este e o conserto do vazamento de before(:all), e a terceira tentativa. A
  # primeira -- transacao por contexto -- quebrou sete exemplos em MariaDB,
  # porque Query#run_read_only_query abre conexao propria e a rake task de
  # notificacoes e outro processo: nenhum dos dois enxerga dado nao commitado.
  # A segunda seria consertar 90 after(:all) na mao.
  #
  # Apagar DEPOIS preserva o que aquela tentativa quebrou: durante o grupo o
  # dado continua commitado e visivel para qualquer conexao. So no fim, quando
  # nenhum exemplo daquele arquivo roda mais, a limpeza acontece.
  #
  # delete_all, nao destroy_all: sem callback, sem ordem de dependencia, e as
  # chaves estrangeiras do schema de teste nao sao aplicadas no SQLite. Em
  # MariaDB a ordem importa, entao desliga-se a checagem durante a varredura.
  def self.sweep!
    restantes = counts.keys
    return if restantes.empty?

    modelos = restantes.filter_map do |nome|
      nome.safe_constantize
    end
    conexao = ActiveRecord::Base.connection
    mysql = conexao.adapter_name == "Mysql2"

    conexao.execute("SET FOREIGN_KEY_CHECKS = 0") if mysql
    begin
      modelos.each do |modelo|
        modelo.delete_all
      rescue StandardError
        next
      end
    ensure
      conexao.execute("SET FOREIGN_KEY_CHECKS = 1") if mysql
    end
  end

  # Pilha de baselines, uma entrada por contexto aberto. Sem ela o inventario
  # mede estado ACUMULADO: depois do primeiro vazamento, todo contexto seguinte
  # reporta o mesmo residuo e 159 arquivos parecem culpados. O que interessa e o
  # delta -- o que este contexto acrescentou e nao limpou.
  def self.baselines
    @baselines ||= []
  end

  def self.push_baseline
    baselines.push(counts)
  end

  def self.pop_delta
    baseline = baselines.pop || {}
    atual = counts
    atual.filter_map do |name, count|
      antes = baseline[name] || 0
      "#{name}=+#{count - antes}" if count > antes
    end.sort
  end
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]

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
    options = Selenium::WebDriver::Chrome::Options.new
    options.args << "--headless=new" unless ENV["BROWSER"]
    options.args << "--no-sandbox"
    options.args << "--disable-gpu"
    options.args << "--disable-dev-shm-usage"
    options.args << "--disable-features=BackForwardCache"

    prefs = {
      "download.default_directory" => DownloadHelpers::PATH.to_s,
      "download.prompt_for_download" => false,
      "plugins.always_open_pdf_externally" => true,
      "safebrowsing.enabled" => true,
      "profile.default_content_settings.popups" => 0,
      "download.directory_upgrade" => true
    }
    options.add_preference(:download, prefs["download.default_directory"])
    options.add_preference(:prefs, prefs)
    options.add_preference(:browser, set_download_behavior: { behavior: "allow" })

    driver = Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: options
    )

    driver.browser.execute_cdp("Page.setDownloadBehavior",
    behavior: "allow",
    downloadPath: DownloadHelpers::PATH.to_s
    )

    driver
  end

  Capybara.default_max_wait_time = 20

  Capybara.default_driver = :selenium
  Capybara.javascript_driver = :selenium

  RSpec.configure do |config|
    config.before(:each, type: :feature) do
      Capybara.current_driver = :selenium
    end
  end

  config.include DateHelpers
  config.include UserHelpers
  config.include PlaceWidgetsHelpers
  config.include RecordSelectHelpers
  config.include DownloadHelpers
  config.include Warden::Test::Helpers
  config.include Devise::Test::IntegrationHelpers, type: :request

  # ActiveScaffold::Registry.current_user_proc is a thread local set by a
  # prepend_before_action on every request. Request specs run the application in
  # the same thread as the example, so it has to be cleared or the signed in
  # user leaks into the following examples.
  config.after(:each, type: :request) do
    ActiveScaffold::Registry.current_user_proc = nil
  end

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

  # NAO envolva o contexto numa transacao. Parece o conserto obvio do vazamento
  # de before(:all) -- e passa inteira em SQLite --, mas quebra sete exemplos em
  # MariaDB, que e o banco do CI e o de producao: Query#run_read_only_query abre
  # um cliente Mysql2 proprio e a rake task maintenance:trigger_notifications e
  # outro processo, e nenhum dos dois enxerga dado nao commitado. Sao os pontos
  # cegos que o AGENTS.md lista, e por isso o SQLite nao acusa. A limpeza vem
  # DEPOIS do grupo, no after(:context) abaixo.
  config.before(:context) do
    LeakDetector.push_baseline if ENV["LEAK_AUDIT"]
  end

  config.after(:context) do
    if ENV["LEAK_AUDIT"]
      delta = LeakDetector.pop_delta
      if delta.any?
        origem = self.class.metadata[:file_path] || self.class.metadata[:full_description]
        puts "LEAK_AUDIT\t#{origem}\t#{delta.join(" ")}"
      end
    end

    # So no grupo de TOPO. Contexto aninhado tem o after(:context) disparado
    # antes do grupo pai terminar, e varrer ali apagaria o before(:all) do pai
    # no meio da execucao dele.
    LeakDetector.sweep! if self.class.metadata[:parent_example_group].nil?
  end

  config.after(:suite) do
    leaked = LeakDetector.leaked_records
    if leaked.any?
      puts "Leaked objects -- Please, try to find and delete them to avoid one test interfering with the other"
      puts "  #{leaked.join("\n  ")}"
      puts "  (LEAK_AUDIT=1 aponta de qual grupo vieram)"
      # Falha, nao so avisa. A divida foi paga pela varredura pos-grupo -- zero
      # vazamento em SQLite e em MariaDB --, entao o que aparecer daqui em diante
      # e regressao, e regressao para a suite. Detector que so avisa volta a ser
      # ignorado: este passou anos assim, cego e mudo. LEAK_CHECK=warn rebaixa,
      # se algum dia for preciso investigar sem travar.
      raise "Vazamento de objetos entre testes" unless ENV["LEAK_CHECK"] == "warn"
    end
  end
end


Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
