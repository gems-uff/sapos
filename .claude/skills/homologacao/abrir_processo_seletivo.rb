#!/usr/bin/env ruby
# frozen_string_literal: true

# Abre e fecha um processo seletivo em homologacao, para que o formulario
# publico de inscricao fique alcancavel enquanto a rodada o exercita.
#
# QUANDO USAR: sempre que precisar do fluxo publico de inscricao (apply). A
# replica nao tem processo aberto, e todos os processos dela vem com
# require_session ligado -- ele faz o prepare_new_admission_application desviar
# antes de o pedido chegar ao controller, entao sao dois campos a mexer, e nao
# so a data.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   bundle exec ruby abrir_processo_seletivo.rb abrir  [<id>]
#   ...exercite o que a rodada precisa em /admissions/<url-simples>/apply/new...
#   bundle exec ruby abrir_processo_seletivo.rb fechar [<id>]
#
# O `abrir` grava os valores originais em <TMPDIR>/sapos_processo_<id>.json, e o
# `fechar` os restaura de la e confere o que gravou. Sao dois comandos, e nao um
# so, porque o que se mede no meio muda a cada rodada.
#
# NAO ESQUECA O FECHAR. Processo aberto na replica aparece na tela publica e
# muda o que a proxima captura enxerga.
#
# Prefira exercitar o create: ele so precisa do processo aberto, enquanto o
# update exigiria o token de uma inscricao de candidato real.

require "selenium-webdriver"
require "date"
require "json"
require "tmpdir"

BASE = (ENV["SAPOS_STAGING_URL"] || abort("defina SAPOS_STAGING_URL")).sub(%r{/\z}, "")
USER = ENV["SAPOS_STAGING_USER"] || abort("defina SAPOS_STAGING_USER")
PASS = ENV["SAPOS_STAGING_PASS"] || abort("defina SAPOS_STAGING_PASS")
abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

ACAO = ARGV[0]
PROCESSO_ID = (ARGV[1] || 5).to_i
ESTADO = File.join(Dir.tmpdir, "sapos_processo_#{PROCESSO_ID}.json")
abort "uso: abrir_processo_seletivo.rb abrir|fechar [<id>]" unless %w[abrir fechar].include?(ACAO)

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--headless=new")
options.add_argument("--window-size=1600,2400")
options.add_argument("--lang=pt-BR")
driver = Selenium::WebDriver.for(:chrome, options: options)
wait = Selenium::WebDriver::Wait.new(timeout: 60)

def settle(driver, wait)
  wait.until { driver.execute_script("return document.readyState") == "complete" }
  wait.until { driver.execute_script("return (typeof jQuery === 'undefined') || jQuery.active === 0") }
rescue Selenium::WebDriver::Error::TimeoutError
  nil
end

# Os links de acao da lista levam o namespace no id e so clicam por JS; navegar
# direto para /edit monta a tela sem o que o JS do active_scaffold precisa.
def abrir_form(driver, wait, id)
  driver.navigate.to("#{BASE}/admission_processes")
  settle(driver, wait)
  link = driver.find_elements(
    id: "as_admissions__admission_processes-edit-#{id}-link"
  ).first
  abort "nao achei o link de edicao do processo #{id}" if link.nil?
  driver.execute_script("arguments[0].click()", link)
  settle(driver, wait)
  sleep 2
end

def campo(driver, id)
  driver.find_elements(id: id).select(&:displayed?).first
end

def gravar(driver, wait, id, fim, exigir_sessao)
  abrir_form(driver, wait, id)
  data = campo(driver, "record_end_date_#{id}")
  abort "campo de data de fim nao encontrado" if data.nil?
  data.clear
  data.send_keys(fim)
  data.send_keys(:escape) # o datepicker cobre o campo seguinte e rouba o clique

  chk = campo(driver, "record_require_session_#{id}")
  abort "checkbox de require_session nao encontrado" if chk.nil?
  chk.click if chk.selected? != exigir_sessao

  driver.find_elements(css: "form input[name='commit']").select(&:displayed?).last.click
  sleep 3
  settle(driver, wait)
end

def aberto?(driver, wait)
  driver.navigate.to("#{BASE}/admissions")
  settle(driver, wait)
  !driver.find_element(css: "body").text.include?("Não há nenhum processo seletivo aberto")
end

begin
  driver.navigate.to("#{BASE}/users/sign_in")
  wait.until { driver.find_element(id: "user_email") }
  driver.find_element(id: "user_email").send_keys(USER)
  senha = driver.find_element(id: "user_password")
  senha.send_keys(PASS)
  senha.submit
  wait.until { !driver.current_url.include?("sign_in") }

  if ACAO == "abrir"
    abort "ja existe #{ESTADO}: feche antes de abrir de novo" if File.exist?(ESTADO)
    abrir_form(driver, wait, PROCESSO_ID)
    original = {
      "end_date" => campo(driver, "record_end_date_#{PROCESSO_ID}")&.attribute("value"),
      "require_session" => campo(driver, "record_require_session_#{PROCESSO_ID}")&.selected?,
      "simple_url" => campo(driver, "record_simple_url_#{PROCESSO_ID}")&.attribute("value"),
    }
    abort "nao li os valores originais; sem eles nao mexo" if original["end_date"].to_s.empty?
    File.write(ESTADO, JSON.pretty_generate(original))

    gravar(driver, wait, PROCESSO_ID, (Date.today + 2).strftime("%d/%m/%Y"), false)
    puts "processo #{PROCESSO_ID} aberto (#{original['simple_url']})"
    puts "  original guardado em #{ESTADO}"
    puts "  aberto? #{aberto?(driver, wait)}"
    puts "  exercite em #{BASE}/admissions/#{original['simple_url']}/apply/new"
    puts "  E FECHE DEPOIS: abrir_processo_seletivo.rb fechar #{PROCESSO_ID}"
  else
    abort "nao achei #{ESTADO}; sem os valores originais nao reverto" unless File.exist?(ESTADO)
    original = JSON.parse(File.read(ESTADO))
    gravar(driver, wait, PROCESSO_ID, original["end_date"], original["require_session"])

    abrir_form(driver, wait, PROCESSO_ID)
    fim = campo(driver, "record_end_date_#{PROCESSO_ID}")&.attribute("value")
    sessao = campo(driver, "record_require_session_#{PROCESSO_ID}")&.selected?
    ok = fim == original["end_date"] && sessao == original["require_session"]
    puts "processo #{PROCESSO_ID} restaurado? #{ok}"
    puts "  fim: #{fim.inspect} (era #{original['end_date'].inspect})"
    puts "  require_session: #{sessao.inspect} (era #{original['require_session'].inspect})"
    puts "  aberto? #{aberto?(driver, wait)}"
    if ok
      File.delete(ESTADO)
    else
      puts "NAO restaurou. Ajuste a mao e so entao apague #{ESTADO}."
    end
  end
ensure
  driver.quit
end
