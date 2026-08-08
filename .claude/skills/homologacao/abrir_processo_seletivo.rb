#!/usr/bin/env ruby
# frozen_string_literal: true

# Abre temporariamente um processo seletivo fechado, submete o formulario
# publico de inscricao SEM o parametro record, e reverte na mesma execucao.
#
# QUANDO USAR: para exercitar o fluxo publico de inscricao (apply) em
# homologacao. A replica nao tem processo aberto, e TODOS os processos dela vem
# com require_session ligado -- que faz o prepare_new_admission_application
# desviar antes de o pedido chegar ao controller. Por isso sao dois campos a
# mexer, e nao so a data.
#
# Exercita o CREATE, e nao o update, de proposito: create so precisa do processo
# aberto, enquanto update precisaria do token de uma inscricao de candidato real.
#
# A reversao roda no ensure e confere o que gravou. Se ela falhar, o script diz
# em letras garrafais o que reverter a mao -- nao deixe processo aberto para tras.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   bundle exec ruby abrir_processo_seletivo.rb [<id>] [<url-simples>]

require "selenium-webdriver"
require "date"

BASE = (ENV["SAPOS_STAGING_URL"] || abort("defina SAPOS_STAGING_URL")).sub(%r{/\z}, "")
USER = ENV["SAPOS_STAGING_USER"]
PASS = ENV["SAPOS_STAGING_PASS"]
abort "URL sem 'staging'" unless BASE.include?("staging")

PROCESSO_ID = (ARGV[0] || 5).to_i
URL_SIMPLES = ARGV[1] || "doutorado-2025-1"

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--headless=new")
options.add_argument("--window-size=1600,2400")
options.add_argument("--lang=pt-BR")
driver = Selenium::WebDriver.for(:chrome, options: options)
driver.manage.timeouts.script_timeout = 30
wait = Selenium::WebDriver::Wait.new(timeout: 60)

def settle(driver, wait)
  wait.until { driver.execute_script("return document.readyState") == "complete" }
  wait.until { driver.execute_script("return (typeof jQuery === 'undefined') || jQuery.active === 0") }
rescue Selenium::WebDriver::Error::TimeoutError
  nil
end

def abrir_form(driver, wait)
  driver.navigate.to("#{BASE}/admission_processes")
  settle(driver, wait)
  link = driver.find_elements(
    id: "as_admissions__admission_processes-edit-#{PROCESSO_ID}-link"
  ).first
  abort "nao achei o link de edicao do processo #{PROCESSO_ID}" if link.nil?
  driver.execute_script("arguments[0].click()", link)
  settle(driver, wait)
  sleep 2
end

def campo(driver, id)
  driver.find_elements(id: id).select(&:displayed?).first
end

# Dois campos, e os dois voltam ao original no ensure: a data de fim, que o
# is_open? do create consulta, e o require_session, que sem desligar faz o
# prepare_new_admission_application desviar antes de chegar na guarda testada.
def gravar(driver, wait, fim, exigir_sessao)
  abrir_form(driver, wait)
  el = campo(driver, "record_end_date_#{PROCESSO_ID}")
  abort "campo de data de fim nao encontrado" if el.nil?
  el.clear
  el.send_keys(fim)
  el.send_keys(:escape) # o datepicker cobre o campo seguinte e rouba o clique

  chk = campo(driver, "record_require_session_#{PROCESSO_ID}")
  abort "checkbox de require_session nao encontrado" if chk.nil?
  chk.click if chk.selected? != exigir_sessao

  driver.find_elements(css: "form input[name='commit']").select(&:displayed?).last.click
  sleep 3
  settle(driver, wait)
end

def aberto?(driver, wait)
  driver.navigate.to("#{BASE}/admissions")
  settle(driver, wait)
  driver.find_element(css: "body").text.include?("Não há nenhum processo seletivo aberto") ? false : true
end

begin
  driver.navigate.to("#{BASE}/users/sign_in")
  wait.until { driver.find_element(id: "user_email") }
  driver.find_element(id: "user_email").send_keys(USER)
  c = driver.find_element(id: "user_password")
  c.send_keys(PASS)
  c.submit
  wait.until { !driver.current_url.include?("sign_in") }
  puts "login ok"

  abrir_form(driver, wait)
  fim_original = campo(driver, "record_end_date_#{PROCESSO_ID}")&.attribute("value")
  sessao = campo(driver, "record_require_session_#{PROCESSO_ID}")&.selected?
  puts "processo #{PROCESSO_ID} (#{URL_SIMPLES})"
  puts "  data de fim original: #{fim_original.inspect}"
  puts "  require_session:      #{sessao.inspect}"
  abort "sem a data original nao mexo" if fim_original.to_s.empty?
  abort "nao li o require_session; sem saber o original nao mexo" if sessao.nil?

  futuro = (Date.today + 2).strftime("%d/%m/%Y")
  puts "\nabrindo ate #{futuro} e desligando require_session..."
  gravar(driver, wait, futuro, false)
  puts "aberto? #{aberto?(driver, wait)}"

  puts "\n--- POST em apply sem o parametro record ---"
  driver.navigate.to("#{BASE}/admissions/#{URL_SIMPLES}/apply/new")
  settle(driver, wait)
  driver.execute_script(<<~JS)
    var f = document.querySelector("form");
    var t = f.querySelector("input[name='authenticity_token']").cloneNode(true);
    var g = document.createElement("form");
    g.method = "post";
    g.action = "#{BASE}/admissions/#{URL_SIMPLES}/apply";
    g.appendChild(t);
    var c = document.createElement("input");
    c.type = "hidden"; c.name = "commit"; c.value = "Enviar inscricao";
    g.appendChild(c);
    document.body.appendChild(g);
    g.submit();
  JS
  sleep 4
  settle(driver, wait)
  puts "url apos o POST: #{driver.current_url}"
  texto = driver.find_element(css: "body").text.to_s
  bloco = driver.find_elements(css: "#errorExplanation, .errorExplanation").first
  puts "bloco de erro na tela:"
  puts (bloco ? bloco.text.to_s.lines.map { |l| "    #{l.strip}" }.reject { |l| l.strip.empty? } : ["    (nenhum)"])
  puts "traz a mensagem da guarda? #{texto.include?('Nenhuma alteração foi recebida') ? 'sim' : 'NAO'}"
  puts "pagina crua de Bad Request? #{texto.include?('Bad Request') ? 'sim' : 'nao'}"
ensure
  if defined?(fim_original) && !fim_original.to_s.empty?
    puts "\nrevertendo (fim #{fim_original}, require_session #{sessao})..."
    begin
      gravar(driver, wait, fim_original, sessao)
      abrir_form(driver, wait)
      puts "  fim agora:            #{campo(driver, "record_end_date_#{PROCESSO_ID}")&.attribute('value').inspect}"
      puts "  require_session agora: #{campo(driver, "record_require_session_#{PROCESSO_ID}")&.selected?.inspect}"
      puts "  aberto? #{aberto?(driver, wait)}   <- tem que ser false"
    rescue => e
      puts "FALHA AO REVERTER: #{e.class}: #{e.message}"
      puts "REVERTA A MAO: processo #{PROCESSO_ID}, fim #{fim_original}, require_session #{sessao}"
    end
  end
  driver.quit
end
