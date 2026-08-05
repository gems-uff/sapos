#!/usr/bin/env ruby
# frozen_string_literal: true

# Captura uma "foto" do SAPOS em homologacao: para cada rota, registra status
# HTTP, tempo, erros de console, requisicoes que falharam, um PNG e o texto
# visivel da pagina. Rodando duas vezes (antes e depois do upgrade) contra o
# MESMO banco, a comparacao isola a mudanca de codigo.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   ruby staging_capture.rb <dir_saida> [arquivo_rotas] [--limit=N]
#
# Variaveis obrigatorias (no arquivo de credenciais, fora do repositorio):
#   SAPOS_STAGING_URL, SAPOS_STAGING_USER, SAPOS_STAGING_PASS
#
# ATENCAO: a saida contem dado real (PNG e texto de pagina). Mantenha local,
# nao versione, nao publique.

require "selenium-webdriver"
require "json"
require "fileutils"
require "digest"

# A partir do Ruby 3.4 a csv deixou de ser default gem e passou a bundled gem:
# sob "bundle exec" ela sai do load path se nao estiver no Gemfile. O CSV aqui e
# so conveniencia de leitura humana -- quem alimenta compare_html.rb e o
# results.json -- entao a ausencia dela nao pode impedir a captura.
begin
  require "csv"
  HAS_CSV = true
rescue LoadError
  HAS_CSV = false
end

def env!(name)
  value = ENV[name]
  abort "Variavel #{name} nao definida. Faca: set -a; source ~/.sapos_staging_env; set +a" if value.nil? || value.empty?
  value
end

BASE = env!("SAPOS_STAGING_URL").sub(%r{/\z}, "")
USER = env!("SAPOS_STAGING_USER")
PASS = env!("SAPOS_STAGING_PASS") # nunca impresso

out_dir = ARGV[0]
abort "uso: ruby staging_capture.rb <dir_saida> [arquivo_rotas] [--limit=N] [--role=<nome>]" if out_dir.nil?
routes_file = ARGV[1] && !ARGV[1].start_with?("--") ? ARGV[1] : "rotas.txt"
limit = ARGV.find { |a| a.start_with?("--limit=") }&.split("=")&.last&.to_i
# O ability.rb decide pelo papel ATIVO (actual_role), nao pelo conjunto de
# papeis do usuario: sem trocar, as telas do aluno voltam negadas mesmo para
# quem tem ROLE_ALUNO. O nome e o que aparece no combo, ex.: --role=Aluno
role = ARGV.find { |a| a.start_with?("--role=") }&.split("=", 2)&.last

if !BASE.include?("staging") && !ARGV.include?("--force")
  abort "A URL (#{BASE}) nao contem 'staging'. Se for intencional, use --force."
end

routes = File.readlines(routes_file, chomp: true)
             .map(&:strip)
             .reject { |r| r.empty? || r.start_with?("#") }
routes = routes.first(limit) if limit&.positive?

FileUtils.mkdir_p(File.join(out_dir, "png"))
FileUtils.mkdir_p(File.join(out_dir, "txt"))

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--headless=new")
options.add_argument("--window-size=1440,2000")
options.add_argument("--hide-scrollbars")
options.add_argument("--force-device-scale-factor=1")
options.add_argument("--lang=pt-BR")
options.add_option("goog:loggingPrefs", { browser: "ALL", performance: "ALL" })

driver = Selenium::WebDriver.for(:chrome, options: options)
wait = Selenium::WebDriver::Wait.new(timeout: 60)

def drain(driver, kind)
  driver.logs.get(kind)
rescue StandardError
  []
end

# Troca o papel ativo pelo combo do cabecalho -- o mesmo caminho do usuario, e
# nao um POST forjado: se o widget mudar de forma, a captura para aqui em vez de
# seguir capturando as telas do papel errado.
#
# O combo so e renderizado para quem tem DOIS ou mais papeis (role_selector no
# application_helper). Usuario com um papel so cai no abort de baixo, que e o
# aviso de que falta associar o papel a conta de captura.
# O papel ativo (actual_role) fica GRAVADO no usuario e atravessa execucoes: uma
# captura sem --role herda o que a anterior deixou. Por isso ele e sempre lido e
# registrado, mesmo quando nao se pede troca -- capturar as telas com o papel
# errado, em silencio, e o pior desfecho possivel.
def papel_ativo(driver)
  driver.execute_script(
    "var s = document.querySelector(\"form[action*='change_role'] select[name='role_id']\");" \
    "return s ? s.options[s.selectedIndex].text.trim() : null;"
  )
rescue StandardError
  nil
end

def switch_role!(driver, wait, base, role_name)
  driver.navigate.to("#{base}/")
  wait.until { driver.execute_script("return document.readyState") == "complete" }
  select_el = begin
    driver.find_element(css: "form[action*='change_role'] select[name='role_id']")
  rescue Selenium::WebDriver::Error::NoSuchElementError
    abort "Combo de troca de papel ausente. A conta #{ENV['SAPOS_STAGING_USER']} " \
          "precisa de pelo menos dois papeis para que ele seja renderizado."
  end
  disponiveis = select_el.find_elements(tag_name: "option").map { |o| o.text.strip }
  unless disponiveis.include?(role_name)
    abort "Papel #{role_name.inspect} nao esta entre os da conta: #{disponiveis.inspect}"
  end

  Selenium::WebDriver::Support::Select.new(select_el).select_by(:text, role_name)
  # O select tem onchange: this.form.submit(), entao a troca ja foi submetida.
  wait.until { driver.execute_script("return document.readyState") == "complete" }

  # Conferir e o ponto: um POST aceito nao garante papel trocado, e capturar 140
  # telas com o papel errado produz um "depois" que parece so ruido.
  driver.navigate.to("#{base}/")
  wait.until { driver.execute_script("return document.readyState") == "complete" }
  ativo = papel_ativo(driver)
  abort "Troca de papel nao pegou: esperado #{role_name.inspect}, ativo #{ativo.inspect}" if ativo != role_name
end

def network_events(entries)
  entries.filter_map do |entry|
    msg = JSON.parse(entry.message)["message"] rescue nil
    next unless msg
    case msg["method"]
    when "Network.responseReceived"
      { kind: :response,
        url: msg.dig("params", "response", "url"),
        status: msg.dig("params", "response", "status"),
        type: msg.dig("params", "type") }
    when "Network.loadingFailed"
      { kind: :failed,
        error: msg.dig("params", "errorText"),
        type: msg.dig("params", "type") }
    end
  end
end

def slug(route)
  s = route.sub(%r{\A/}, "").gsub("/", "_")
  s.empty? ? "root" : s
end

begin
  # --- login ---------------------------------------------------------------
  driver.navigate.to("#{BASE}/users/sign_in")
  wait.until { driver.find_element(id: "user_email") }
  driver.find_element(id: "user_email").send_keys(USER)
  field = driver.find_element(id: "user_password")
  field.send_keys(PASS)
  field.submit
  begin
    wait.until { !driver.current_url.include?("sign_in") }
  rescue Selenium::WebDriver::Error::TimeoutError
    # Continuou na tela de login: reporta o motivo em vez de estourar sem contexto.
    reason = begin
      driver.find_element(id: "error_login").text.to_s.strip
    rescue StandardError
      begin
        driver.execute_script("return document.body ? document.body.innerText : ''").to_s[0, 300]
      rescue StandardError
        "(nao foi possivel ler a pagina)"
      end
    end
    abort "Login recusado para #{USER}. Mensagem da aplicacao: #{reason}"
  end
  puts "login ok como #{USER} -> #{driver.current_url}"
  switch_role!(driver, wait, BASE, role) if role

  # Registrado em arquivo proprio, e nao no results.json, para nao mexer no
  # formato que o compare_html.rb consome.
  ativo = papel_ativo(driver) || "(conta com um papel so)"
  puts "papel ativo: #{ativo}"
  File.write(File.join(out_dir, "papel.txt"), "#{ativo}\n")
  if role.nil? && ativo != "(conta com um papel so)"
    puts "AVISO: sem --role, a captura herdou o papel #{ativo.inspect} deixado pela execucao anterior."
  end

  results = []

  routes.each_with_index do |route, i|
    url = "#{BASE}#{route}"
    drain(driver, :performance)
    drain(driver, :browser)

    started = Time.now
    error = nil
    begin
      driver.navigate.to(url)
      wait.until { driver.execute_script("return document.readyState") == "complete" }
      # O active_scaffold carrega listas por AJAX; sem esperar a fila do jQuery
      # esvaziar, a captura pode pegar a pagina antes do conteudo e produzir
      # diferencas falsas entre as duas execucoes.
      wait.until { driver.execute_script("return (typeof jQuery === 'undefined') || jQuery.active === 0") }
    rescue StandardError => e
      error = "#{e.class}: #{e.message.lines.first&.strip}"
    end
    elapsed_ms = ((Time.now - started) * 1000).round

    events = network_events(drain(driver, :performance))
    doc = events.find { |e| e[:kind] == :response && e[:type] == "Document" }
    broken = events.select { |e| e[:kind] == :response && e[:status].to_i >= 400 }
    # Um net::ERR_ABORTED sobre um Document, numa varredura que navega rota a
    # rota, e a requisicao da pagina ANTERIOR cancelada pela navegacao atual --
    # nao asset faltando. Medido na homologacao da issue #639, sobre o mesmo
    # codigo: /advisement_authorizations acusa failed=1 quando precedida de
    # /admissions (a rota mais lenta da lista) e failed=0 quando capturada
    # sozinha. Na captura do baseline, com a mesma ordem, ela acusou 0 -- ou seja,
    # o sinal aparece e desaparece conforme o tempo de resposta, nao conforme o
    # codigo, e numa comparacao vira falso positivo. Qualquer outro errorText, e
    # qualquer aborto que nao seja de Document, continua contando.
    failed = events.select do |e|
      e[:kind] == :failed && !(e[:error] == "net::ERR_ABORTED" && e[:type] == "Document")
    end

    console = drain(driver, :browser)
                .select { |m| m.level == "SEVERE" }
                .map { |m| m.message.to_s.lines.first.to_s.strip }
                .uniq

    title = driver.title.to_s rescue ""
    text = begin
      driver.execute_script("return document.body ? document.body.innerText : ''").to_s
    rescue StandardError
      ""
    end

    # A versao aparece no rodape de toda pagina e muda entre as duas execucoes.
    # Sem neutralizar, as 125 rotas apareceriam como alteradas.
    # Datas NAO sao normalizadas de proposito: mudanca de formato de data e uma
    # das regressoes procuradas (fix_rails7_date_format.rb).
    normalized = text.gsub(/Vers[aã]o\s+\S+/, "Versao <VER>")

    name = slug(route)
    File.write(File.join(out_dir, "txt", "#{name}.txt"), text)

    begin
      height = driver.execute_script(
        "return Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)"
      ).to_i
      driver.manage.window.resize_to(1440, [[height + 120, 900].max, 8000].min)
      driver.save_screenshot(File.join(out_dir, "png", "#{name}.png"))
      driver.manage.window.resize_to(1440, 2000)
    rescue StandardError => e
      error ||= "screenshot: #{e.class}"
    end

    results << {
      route: route,
      status: doc ? doc[:status] : nil,
      ms: elapsed_ms,
      title: title,
      text_sha: Digest::SHA256.hexdigest(normalized)[0, 16],
      text_bytes: text.bytesize,
      console_errors: console.size,
      broken_requests: broken.size,
      failed_requests: failed.size,
      final_url: driver.current_url,
      error: error,
      console_sample: console.first(3),
      broken_sample: broken.first(5).map { |b| "#{b[:status]} #{b[:url]}" },
      # Sem esta amostra, um failed_requests que sobe de 0 para 1 na comparacao
      # nao diz o que falhou, e a captura do baseline nao pode ser refeita depois
      # que a versao nova subiu. O errorText distingue o benigno (net::ERR_ABORTED
      # de requisicao cancelada) do que merece investigacao.
      failed_sample: failed.first(5).map { |f| "#{f[:error]} (#{f[:type]})" }
    }

    flag = if error then "ERRO"
           elsif doc && doc[:status].to_i >= 400 then "HTTP #{doc[:status]}"
           elsif broken.any? || failed.any? then "assets"
           elsif console.any? then "console"
           else "ok"
           end
    puts format("[%3d/%3d] %-45s %-9s %5dms", i + 1, routes.size, route, flag, elapsed_ms)
  end

  if HAS_CSV
    CSV.open(File.join(out_dir, "results.csv"), "w") do |csv|
      csv << %w[route status ms title text_sha text_bytes console_errors broken_requests failed_requests final_url error]
      results.each do |r|
        csv << [r[:route], r[:status], r[:ms], r[:title], r[:text_sha], r[:text_bytes],
                r[:console_errors], r[:broken_requests], r[:failed_requests], r[:final_url], r[:error]]
      end
    end
  else
    puts "\n(sem a gem csv neste Ruby; results.csv nao gerado -- a comparacao usa o results.json)"
  end
  File.write(File.join(out_dir, "results.json"), JSON.pretty_generate(results))
  puts "\nsaida em #{out_dir}/ (#{"results.csv, " if HAS_CSV}results.json, png/, txt/)"
ensure
  driver&.quit
end
