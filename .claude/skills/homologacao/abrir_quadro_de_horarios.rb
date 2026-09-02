#!/usr/bin/env ruby
# frozen_string_literal: true

# Cria em homologacao um Quadro de Horarios com as janelas ABERTAS hoje, para
# que as telas de inscricao do aluno fiquem alcancaveis.
#
# QUANDO USAR: so quando a captura precisar da tela de inscricao
# (/enrollment/:id/enroll/:ano-:semestre) e nao houver periodo aberto. O banco de
# homologacao e replica de producao: se o ultimo quadro ja estiver aberto, NAO
# rode isto -- capture com o que esta la. O script recusa duplicar um quadro que
# ja exista para o mesmo ano/semestre.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   bundle exec ruby abrir_quadro_de_horarios.rb <ano> <semestre> [--confirmar]
#
# Sem --confirmar ele so mostra o que faria (as datas calculadas) e sai.
#
# ATENCAO: abrir um periodo muda o que o sistema considera semestre corrente e da
# assunto a rake task de notificacoes. Confira a CustomVariable redirect_email
# ANTES (tabela verdade no SKILL.md): vazio trava tudo, um endereco redireciona,
# e AUSENTE envia ao destinatario real.

require "selenium-webdriver"
require "date"

def env!(name)
  v = ENV[name]
  abort "Variavel #{name} nao definida. Faca: set -a; source ~/.sapos_staging_env; set +a" if v.nil? || v.empty?
  v
end

BASE = env!("SAPOS_STAGING_URL").sub(%r{/\z}, "")
USER = env!("SAPOS_STAGING_USER")
PASS = env!("SAPOS_STAGING_PASS") # nunca impresso

ano = ARGV[0]
semestre = ARGV[1]
confirmar = ARGV.include?("--confirmar")
abort "uso: ruby abrir_quadro_de_horarios.rb <ano> <semestre> [--confirmar]" if ano.nil? || semestre.nil?

if !BASE.include?("staging") && !ARGV.include?("--force")
  abort "A URL (#{BASE}) nao contem 'staging'. Se for intencional, use --force."
end

hoje = Date.today
def fmt(data, fim: false)
  # O formulario usa o mesmo formato que exibe: "27 Jul 2026 00:00:00".
  meses = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
  pt = { "Feb" => "Fev", "Apr" => "Abr", "May" => "Mai", "Aug" => "Ago",
         "Sep" => "Set", "Oct" => "Out", "Dec" => "Dez" }
  mes = meses[data.month - 1]
  mes = pt[mes] || mes
  "#{format('%02d', data.day)} #{mes} #{data.year} #{fim ? '23:59:59' : '00:00:00'}"
end

# Janelas generosas e escalonadas: a principal fecha primeiro, depois a de
# insercao, depois a de remocao -- e a ordem entre as duas ultimas importa,
# porque e ela que separa "so insercao aberta" de "so remocao aberta".
DATAS = {
  "record_enrollment_start_" => fmt(hoje),
  "record_enrollment_end_" => fmt(hoje + 4, fim: true),
  "record_period_start_" => fmt(hoje),
  "record_enrollment_insert_" => fmt(hoje + 35, fim: true),
  "record_enrollment_remove_" => fmt(hoje + 65, fim: true),
  "record_period_end_" => fmt(hoje + 150, fim: true),
  "record_grades_deadline_" => fmt(hoje + 180, fim: true),
}

puts "Quadro #{ano}.#{semestre} em #{BASE}"
DATAS.each { |campo, valor| puts "  #{campo.sub('record_', '').chomp('_').ljust(20)} #{valor}" }
unless confirmar
  puts "\n(simulacao -- rode de novo com --confirmar para criar)"
  exit 0
end

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--headless=new")
options.add_argument("--window-size=1440,2000")
options.add_argument("--lang=pt-BR")
driver = Selenium::WebDriver.for(:chrome, options: options)
wait = Selenium::WebDriver::Wait.new(timeout: 60)

def settle(driver, wait)
  wait.until { driver.execute_script("return document.readyState") == "complete" }
  wait.until { driver.execute_script("return (typeof jQuery === 'undefined') || jQuery.active === 0") }
rescue Selenium::WebDriver::Error::TimeoutError
  nil
end

begin
  driver.navigate.to("#{BASE}/users/sign_in")
  wait.until { driver.find_element(id: "user_email") }
  driver.find_element(id: "user_email").send_keys(USER)
  campo = driver.find_element(id: "user_password")
  campo.send_keys(PASS)
  campo.submit
  wait.until { !driver.current_url.include?("sign_in") }
  puts "login ok como #{USER}"

  # Duplicar quadro do mesmo semestre confunde o ClassSchedule.find_by do
  # controller; melhor recusar do que criar o segundo.
  driver.navigate.to("#{BASE}/class_schedules")
  settle(driver, wait)
  if driver.page_source =~ %r{#{ano}\s*</td>\s*<td[^>]*>\s*#{semestre}\s*<}m
    abort "Ja existe quadro #{ano}.#{semestre} -- nao vou duplicar. Ajuste as datas dele a mao se precisar."
  end

  driver.navigate.to("#{BASE}/class_schedules/new")
  settle(driver, wait)

  Selenium::WebDriver::Support::Select.new(
    driver.find_element(id: "record_year_")
  ).select_by(:text, ano.to_s)
  Selenium::WebDriver::Support::Select.new(
    driver.find_element(id: "record_semester_")
  ).select_by(:text, semestre.to_s)

  DATAS.each do |id, valor|
    el = driver.find_elements(id: id).first
    abort "campo #{id} nao encontrado -- o formulario mudou" if el.nil?
    el.clear
    el.send_keys(valor)
    # O datepicker do jquery-ui fica sobre o proximo campo e rouba o clique.
    el.send_keys(:escape)
  end

  driver.find_element(name: "commit").click
  sleep 3
  settle(driver, wait)

  # Conferir pela lista, e nao pela ausencia de erro na tela.
  driver.navigate.to("#{BASE}/class_schedules")
  settle(driver, wait)
  ok = driver.page_source.include?(">#{ano}<") && driver.page_source.include?(fmt(hoje).split.first)
  puts ok ? "quadro #{ano}.#{semestre} criado" : "NAO confirmei o quadro na lista -- verifique a mao"
ensure
  driver.quit
end
