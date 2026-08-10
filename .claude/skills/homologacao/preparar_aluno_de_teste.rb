#!/usr/bin/env ruby
# frozen_string_literal: true

# Garante em homologacao o conjunto de dados que as telas do papel Aluno exigem,
# criando o que faltar e deixando em paz o que ja existe.
#
# QUANDO USAR: sempre depois de o banco de homologacao ser regerado a partir de
# producao. O dump traz os dados reais e nao traz nada disto, entao as rotas do
# routes_aluno.txt param de responder ate o conjunto ser refeito. Rodar sem
# necessidade nao custa nada: cada etapa confere antes e pula o que achar.
#
# O QUE ELE GARANTE:
#   1. matricula regular, para as telas de inscricao;
#   2. matricula desligada, com banca e SEM data de defesa -- combinacao que a
#      replica nunca tem, e que a tela do proprio aluno precisa.
#
# O QUE ELE NAO FAZ, de proposito: criar o aluno e associa-lo a conta de
# captura. Ver "Preparando o ambiente para o papel de aluno" no SKILL.md -- a
# ordem errada ali faz o rescue do Enrollment#create_user! apagar a conta de
# captura. Se o aluno nao existir, este script para e diz o que fazer a mao.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   bundle exec ruby preparar_aluno_de_teste.rb [--confirmar]
#
# Sem --confirmar so mostra o que faria. Ao fim, imprime as linhas prontas do
# routes_aluno.txt, com os ids que existem agora -- eles mudam a cada regeracao.

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

confirmar = ARGV.include?("--confirmar")
if !BASE.include?("staging") && !ARGV.include?("--force")
  abort "A URL (#{BASE}) nao contem 'staging'. Se for intencional, use --force."
end

ALUNO = "ZZ-TESTE-HOMOLOG"
REGULAR = "ZZTESTEHOMOLOG1"
DESLIGADA = "ZZ-TESTE-HOMOLOG-DESLIGADA"
ADMISSAO = Date.today << 36
DESLIGAMENTO = Date.today << 12
SEMESTRE_SEM_QUADRO = "2030-1"

puts "Conjunto do aluno de teste em #{BASE}"
puts "  aluno:              #{ALUNO}"
puts "  matricula regular:  #{REGULAR}"
puts "  matricula desligada: #{DESLIGADA} (desligamento #{DESLIGAMENTO.strftime('%m/%Y')}, sem data de defesa)"
unless confirmar
  puts "\n(simulacao -- rode de novo com --confirmar para criar o que faltar)"
  exit 0
end

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--headless=new")
options.add_argument("--window-size=1440,2400")
options.add_argument("--lang=pt-BR")
driver = Selenium::WebDriver.for(:chrome, options: options)
wait = Selenium::WebDriver::Wait.new(timeout: 60)

def settle(driver, wait)
  wait.until { driver.execute_script("return document.readyState") == "complete" }
  wait.until { driver.execute_script("return (typeof jQuery === 'undefined') || jQuery.active === 0") }
rescue Selenium::WebDriver::Error::TimeoutError
  nil
end

# O record_select nao filtra com send_keys de uma vez: a busca sai vazia e a
# lista volta sem filtro, com outro registro no topo. Digitar devagar e esperar
# o item aparecer e o que evita associar o registro errado em silencio.
#
# Os itens sao li.record; o primeiro li da lista e o cabecalho "Records Found",
# e clicar nele nao associa nada -- o formulario segue sem o registro e a
# gravacao falha sem dizer por que. A lista tambem se refaz a cada resposta do
# autocomplete, entao achar e clicar tem que ficar juntos.
def record_select(driver, wait, campo_id, texto, preferir: nil)
  campo = driver.find_element(id: campo_id)
  campo.click
  texto.each_char do |c|
    campo.send_keys(c)
    sleep 0.3
  end
  sleep 1.5
  escolhido = nil
  6.times do
    itens = driver.find_elements(css: "li.record").select(&:displayed?)
    if itens.empty?
      sleep 0.5
      next
    end
    item = (preferir && itens.find { |el| el.text.to_s.include?(preferir) }) || itens.first
    escolhido = item.text.strip
    item.click
    break
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    escolhido = nil
    sleep 0.5
  end
  settle(driver, wait)
  escolhido
end

def selecionar(driver, id, valor)
  el = driver.find_elements(id: id).first
  return nil if el.nil?
  Selenium::WebDriver::Support::Select.new(el).select_by(:value, valor.to_s)
end

def selecionar_texto_ou_primeiro(driver, id, preferido)
  el = driver.find_elements(id: id).first
  return nil if el.nil?
  sel = Selenium::WebDriver::Support::Select.new(el)
  begin
    sel.select_by(:text, preferido)
  rescue Selenium::WebDriver::Error::NoSuchElementError
    opcao = sel.options.find do |o|
      o.text.strip.length.positive? && o.attribute("value").to_s.length.positive?
    end
    abort "sem opcao utilizavel em #{id}" if opcao.nil?
    opcao.click
  end
  sel.first_selected_option.text.strip
end

# Conferir sempre pela lista ordenada por id decrescente: a ordem natural e
# paginada, e o registro recem-criado nao aparece na primeira pagina -- foi
# assim que uma criacao bem-sucedida passou por "nao foi criada".
def achar(driver, wait, recurso, numero)
  driver.navigate.to("#{BASE}/#{recurso}?sort=id&sort_direction=DESC")
  settle(driver, wait)
  linha = driver.find_elements(css: "table tbody tr").find { |tr| tr.text.include?(numero) }
  return nil if linha.nil?
  linha.find_elements(css: "a[id*='-link']")
       .map { |a| a.attribute("id")[/-(\d+)-link\z/, 1] }.compact.first || "?"
end

def gravar(driver)
  botoes = driver.find_elements(css: "form input[name='commit']").select(&:displayed?)
  abort "nenhum botao de submit visivel" if botoes.empty?
  botoes.last.click
  sleep 3
end

def criar_matricula(driver, wait, numero, aluno)
  driver.navigate.to("#{BASE}/enrollments/new")
  settle(driver, wait)
  driver.find_element(id: "record_enrollment_number_").send_keys(numero)
  # Ha mais de um aluno com o rotulo de teste; o que interessa e o associado a
  # conta de captura, senao a tela do aluno nao mostra a matricula.
  escolhido = record_select(driver, wait, "record_student_", aluno, preferir: "Aluno")
  if escolhido.nil?
    abort <<~FIM
      Nao achei o aluno #{aluno} associado a conta de captura.
      Faca os passos 1 e 2 de "Preparando o ambiente para o papel de aluno" no
      SKILL.md, nessa ordem -- inverte-la apaga a conta de captura -- e rode de novo.
    FIM
  end
  puts "  aluno: #{escolhido}"
  selecionar(driver, "record_admission_date_2i", ADMISSAO.month)
  selecionar(driver, "record_admission_date_1i", ADMISSAO.year)
  # Tipo de Matricula precisa ter "Com usuario" marcado, senao o _valid_enrollment
  # nega o acesso do proprio aluno e a tela nunca chega a renderizar.
  puts "  tipo:  #{selecionar_texto_ou_primeiro(driver, 'record_enrollment_status_', 'Regular')}"
  puts "  nivel: #{selecionar_texto_ou_primeiro(driver, 'record_level_', 'Mestrado')}"
  gravar(driver)
  settle(driver, wait)
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

  puts "\n1/4 matricula regular"
  id_regular = achar(driver, wait, "enrollments", REGULAR)
  if id_regular
    puts "  ja existe (id #{id_regular})"
  else
    criar_matricula(driver, wait, REGULAR, ALUNO)
    id_regular = achar(driver, wait, "enrollments", REGULAR)
    abort "NAO consegui criar #{REGULAR}" if id_regular.nil?
    puts "  criada (id #{id_regular})"
  end

  puts "\n2/4 matricula desligada"
  id_desligada = achar(driver, wait, "enrollments", DESLIGADA)
  if id_desligada
    puts "  ja existe (id #{id_desligada})"
  else
    criar_matricula(driver, wait, DESLIGADA, ALUNO)
    id_desligada = achar(driver, wait, "enrollments", DESLIGADA)
    abort "NAO consegui criar #{DESLIGADA}" if id_desligada.nil?
    puts "  criada (id #{id_desligada})"
  end

  # O desligamento tem tela propria porque o campo aninhado no formulario da
  # matricula nao efetiva (issue #291).
  puts "\n3/4 desligamento"
  if achar(driver, wait, "dismissals", DESLIGADA)
    puts "  ja existe"
  else
    driver.navigate.to("#{BASE}/dismissals/new")
    settle(driver, wait)
    puts "  matricula: #{record_select(driver, wait, 'record_enrollment_', DESLIGADA)}"
    selecionar(driver, "record_date_2i", DESLIGAMENTO.month)
    selecionar(driver, "record_date_1i", DESLIGAMENTO.year)
    puts "  motivo:    #{selecionar_texto_ou_primeiro(driver, 'record_dismissal_reason_', 'Titulação')}"
    gravar(driver)
    settle(driver, wait)
    puts achar(driver, wait, "dismissals", DESLIGADA) ? "  criado" : "  NAO confirmei o desligamento"
  end

  puts "\n4/4 banca"
  if achar(driver, wait, "thesis_defense_committee_participations", DESLIGADA)
    puts "  ja existe"
  else
    driver.navigate.to("#{BASE}/thesis_defense_committee_participations/new")
    settle(driver, wait)
    puts "  matricula: #{record_select(driver, wait, 'record_enrollment_', DESLIGADA)}"
    puts "  professor: #{record_select(driver, wait, 'record_professor_', 'a')}"
    gravar(driver)
    settle(driver, wait)
    puts achar(driver, wait, "thesis_defense_committee_participations", DESLIGADA) ? "  criada" : "  NAO confirmei a banca"
  end

  puts <<~FIM

    Ponha estas linhas no routes_aluno.txt (os ids mudam a cada regeracao):

    /enrollment/#{id_regular}
    /enrollment/#{id_regular}/enroll/<ano-semestre com quadro aberto>
    /enrollment/#{id_regular}/enroll/#{SEMESTRE_SEM_QUADRO}
    /enrollment/#{id_desligada}
  FIM
ensure
  driver.quit
end
