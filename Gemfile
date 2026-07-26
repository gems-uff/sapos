# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Esta diretiva nao escolhe o Ruby, o .ruby-version escolhe; ela recusa rodar
# no interpretador errado, e por isso e uma faixa (aceita 3.4.11, barra 3.5).
# Serie 3.4: a 3.2 chegou ao fim de vida em 01/04/2026 e nao recebe mais nem
# correcao de seguranca (issue #639). A 3.3 esta so em manutencao de seguranca
# e vence em 31/03/2027; a 3.4 esta em manutencao normal e serve tambem ao
# Rails 8 (que exige >= 3.2), entao nao precisa ser refeita nesse salto.
# Piso 3.4.10: ultimo patch da serie. O piso antigo (3.2.11) existia para
# garantir o uri >= 0.12.5 do stdlib (CVE-2025-61594, vazamento de credencial
# via URI#+); a serie 3.4 ja traz o uri bem acima disso.
ruby "~> 3.4.10"

# ─── Framework e servidor ────────────────────────────────────────────────
gem "rails", "~> 7.2.3", ">= 7.2.3.1"
gem "rack", "~> 2.2.23"
gem "puma", "~> 7.2", ">= 7.2.1"
gem "sprockets-rails"                    # asset pipeline
gem "bootsnap", require: false           # cache de boot (config/boot.rb)
gem "nokogiri", ">= 1.18.9"              # piso de seguranca (parser HTML/XML)
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# ─── Assets / front-end ──────────────────────────────────────────────────
gem "sassc-rails"                        # SCSS
gem "coffee-rails"                       # CoffeeScript
gem "jquery-rails"
gem "jquery-ui-rails", "7.0.0"           # rubygems (jQuery UI 1.13.0). 8.0.0 corrige a
                                         # CVE-2022-31160 mas reestrutura os assets (quebra
                                         # o application.css) e o app nao usa checkboxradio.
gem "font-awesome-rails"                 # iconografia

# ─── Autenticacao e autorizacao ──────────────────────────────────────────
gem "devise", "~> 5.0", ">= 5.0.4"
gem "devise_invitable", "~> 2.0.0"
gem "cancancan"
gem "recaptcha", require: "recaptcha/rails"
gem "dotenv-rails", require: "dotenv/load"   # ENV a partir de .env (recaptcha etc.)

# ─── UI administrativa / scaffolding ─────────────────────────────────────
gem "active_scaffold", "~> 4.0.13"
gem "active_scaffold_duplicate", ">= 1.1.0"
gem "recordselect"
gem "simple-navigation"                  # menu (config/navigation.rb)
gem "cocoon"                             # nested forms

# ─── Geracao de PDF ──────────────────────────────────────────────────────
# O prawn 2.5.0 declara matrix (~> 0.4) no gemspec, entao nao precisamos mais
# declarar matrix aqui (o prawn 2.4.0 usava Matrix sem declarar, e matrix virou
# bundled gem no Ruby 3.1 -- por isso a linha explicita existia antes).
gem "prawn"
gem "prawn-table"
gem "prawn-rails"
gem "prawn-qrcode"

# ─── Planilhas (XLSX) ────────────────────────────────────────────────────
gem "caxlsx"
gem "caxlsx_rails"

# ─── Relatorios / templates ──────────────────────────────────────────────
gem "liquid"                             # templates de relatorio/notificacao
gem "redcarpet"                          # Markdown (pagina de creditos)

# ─── Upload de arquivos ──────────────────────────────────────────────────
gem "carrierwave", ">= 3.0.7"
gem "carrierwave-activerecord", git: "https://github.com/gems-uff/carrierwave-activerecord.git", branch: "rails7"

# ─── Dominio / infraestrutura de app ─────────────────────────────────────
gem "paper_trail"                        # versionamento/auditoria
gem "activerecord-session_store"         # sessao no banco (initializers/session_store.rb)
gem "rufus-scheduler"                    # agendamento de notificacoes
gem "validates_timeliness", "~> 7.1.0"   # validacao de datas
gem "exception_notification"             # notifica excecoes

# ─── Ambientes ───────────────────────────────────────────────────────────
group :development do
  gem "web-console"                      # console nas paginas de erro
  gem "rubocop", require: false
  gem "rubocop-rails_config", require: false
  # Seguranca / analise estatica (rodadas via CLI, dai require: false)
  gem "bundler-audit", require: false    # CVE em dependencias (bundle audit)
  gem "brakeman", require: false         # SAST de Rails (SQLi, XSS, ...)
end

group :development, :test do
  gem "sqlite3", "~> 2.9.5"              # banco de dev/test; piso 2.9.5: CVE-2026-54620
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
end

# Gems fora do install default para um checkout limpo rodar em SQLite sem
# servidor de banco nem cliente MySQL nativo. Producao precisa da mysql2; CI e
# a skill suite-mariadb tambem, e optam por ela instalando este grupo.
group :production do
  gem "mysql2"                           # driver MySQL/MariaDB (producao, CI, MariaDB local)
end

group :doc do
  # sdoc puxa rdoc (>= 5.0), resolvido em 7.2.0 -- acima do piso de seguranca
  # antigo (rdoc >= 6.5.1.1, CVE-2024-27281), entao nao declaramos rdoc aqui.
  gem "sdoc", require: false             # bundle exec rake doc:rails
end
