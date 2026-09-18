# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# O .ruby-version escolhe o interpretador; esta diretiva so recusa o errado.
# Serie 3.4 porque a 3.3 vence em 31/03/2027 e ja esta so em manutencao de
# seguranca, e a 3.4 serve ao Rails 8 -- sobrevive a esse salto.
ruby "~> 3.4.10"

# Nao ha piso de seguranca (">= x.y.z") neste arquivo. Piso envelhece calado
# quando sai a correcao seguinte; o que garante que o lock nao carrega CVE
# conhecida e o bundle-audit, que o CI roda contra a base de advisories do dia.

# ─── Framework e servidor ────────────────────────────────────────────────
gem "rails", "~> 8.1.3"                  # minor do Rails e migracao: decisao a parte
gem "sprockets-rails"                    # asset pipeline
gem "bootsnap", require: false           # cache de boot (config/boot.rb)
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# ─── Assets / front-end ──────────────────────────────────────────────────
gem "dartsass-sprockets"                 # compilador sass; a 4.3 do AS deixou de puxa-lo, mantemos o pin direto (#621)
gem "coffee-rails"
gem "jquery-rails"
gem "jquery-ui-rails", "~> 8.0"          # major mexe no layout de assets e o AS ramifica por versao (#638)
gem "font-awesome-rails"

# ─── Autenticacao e autorizacao ──────────────────────────────────────────
gem "devise", "~> 5.0"                   # major de auth exige migracao: decisao a parte
gem "devise_invitable"
gem "cancancan"
gem "recaptcha", require: "recaptcha/rails"

# ─── UI administrativa / scaffolding ─────────────────────────────────────
gem "active_scaffold", "~> 4.3.2"        # upgrade em saltos de minor; trava a serie 4.3 (#621)
gem "active_scaffold_duplicate"
gem "recordselect"
gem "simple-navigation"                  # menu (config/navigation.rb)
gem "cocoon"                             # nested forms

# ─── Geracao de PDF ──────────────────────────────────────────────────────
# O prawn ja declara matrix no gemspec; nao redeclare aqui.
gem "prawn"
gem "prawn-table"
gem "prawn-rails"
gem "prawn-qrcode"

# ─── Planilhas (XLSX) ────────────────────────────────────────────────────
gem "caxlsx"
gem "caxlsx_rails"
gem "roo"                                # leitura de planilhas xlsx (importação de notas)

# ─── Relatorios / templates ──────────────────────────────────────────────
gem "liquid"                             # templates de relatorio/notificacao
gem "redcarpet"                          # Markdown (pagina de creditos)

# ─── Upload de arquivos ──────────────────────────────────────────────────
gem "carrierwave"
gem "carrierwave-activerecord", git: "https://github.com/gems-uff/carrierwave-activerecord.git", branch: "rails8"

# ─── Dominio / infraestrutura de app ─────────────────────────────────────
gem "paper_trail"                        # versionamento/auditoria
gem "activerecord-session_store"         # sessao no banco (initializers/session_store.rb)
gem "rufus-scheduler"                    # agendamento de notificacoes
gem "validates_timeliness", "~> 8.0"     # validacao de datas; o major acompanha o do Rails (8.x pede activemodel 8)
gem "exception_notification"             # notifica excecoes

# ─── Ambientes ───────────────────────────────────────────────────────────
group :development do
  gem "web-console"                      # console nas paginas de erro
  gem "rubocop", require: false
  gem "rubocop-rails_config", require: false
  # Seguranca / analise estatica
  gem "bundler-audit", require: false    # CVE em dependencias (bundle audit)
  gem "brakeman", require: false         # SAST de Rails (SQLi, XSS, ...)
end

group :development, :test do
  # Producao roda Apache + Passenger; o puma serve ao `rails s` e ao servidor
  # que o Capybara sobe nos feature specs (Capybara.server em rails_helper).
  # A serie fica travada por esse segundo uso: o Capybara instancia
  # Puma::Server e chama binder e log_writer diretamente, e e major que mexe
  # nessas superficies.
  gem "puma", "~> 8.0"
  gem "sqlite3"                          # banco de dev/test
  gem "awesome_print"
  gem "binding_of_caller"
  gem "better_errors"
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "pry"
  gem "letter_opener_web"               # /letter_opener mostra e-mails "enviados"
  gem "rails-erd"                        # diagrama entidade-relacionamento
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "rspec-collection_matchers"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
  gem "simplecov"
  # O Cobertura XML e o formato que a API de cobertura do GitHub aceita; o
  # simplecov sozinho so escreve HTML e o .resultset.json.
  gem "simplecov-cobertura"
  gem "pdf-reader", require: "pdf/reader"   # le o texto do PDF no golden-master
end

# Fora do install default para um checkout limpo rodar em SQLite sem servidor de
# banco. Producao, CI e a skill suite-mariadb instalam este grupo.
group :production do
  gem "mysql2"                           # driver MySQL/MariaDB (producao, CI, MariaDB local)
end

group :doc do
  gem "sdoc", require: false             # bundle exec rake doc:rails
end
