#!/usr/bin/env ruby
# frozen_string_literal: true

# Cria em homologacao uma matricula do aluno de teste que esteja DESLIGADA, COM
# BANCA e SEM DATA DE DEFESA -- a combinacao que a replica nao tem e que a tela
# do aluno precisa para ser evidencia.
#
# POR QUE PRECISA SER DO ALUNO DE TESTE: a tela que interessa e
# /enrollment/:id, a do proprio aluno. Uma matricula qualquer da replica nao
# serve, porque nao ha como logar como o aluno dela; o _valid_enrollment exige
# que a matricula seja de quem esta logado.
#
# POR QUE NAO REUSAR A MATRICULA 3074: desligamento esconde a parte de inscricao
# da tela e faz /enroll redirecionar com "matricula desligada". Reusar aquela
# matricula apagaria a evidencia das telas de inscricao na mesma rodada.
#
# POR QUE TRES TELAS E NAO SO A DE MATRICULA: o formulario de matricula tem
# desligamento e banca aninhados, mas o desligamento por ali nao efetiva (#291).
# As telas proprias funcionam.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   bundle exec ruby preparar_matricula_desligada.rb [--confirmar]
#
# Sem --confirmar so mostra o que faria. Ao fim, imprime o id da matricula, que
# deve entrar no routes_aluno.txt.
#
# LIMPEZA: o numero da matricula leva ZZ-TESTE-HOMOLOG, que e por onde a varredura
# de limpeza acha o que remover ao fim da rodada.

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
NUMERO = "ZZ-TESTE-HOMOLOG-DESLIGADA"
ADMISSAO = Date.today << 36
DESLIGAMENTO = Date.today << 12

puts "Matricula #{NUMERO} em #{BASE}"
puts "  aluno         #{ALUNO}"
puts "  admissao      #{ADMISSAO.strftime('%m/%Y')}"
puts "  desligamento  #{DESLIGAMENTO.strftime('%m/%Y')}"
puts "  defesa        (em branco -- e o que faz a tela quebrar antes da correcao)"
unless confirmar
  puts "\n(simulacao -- rode de novo com --confirmar para criar)"
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
# e clicar nele nao associa nada -- o formulario segue sem aluno e a gravacao
# falha sem dizer por que. E a busca pode devolver mais de um registro parecido,
# entao `preferir` escolhe qual, em vez de aceitar o primeiro.
def record_select(driver, wait, campo_id, texto, preferir: nil)
  campo = driver.find_element(id: campo_id)
  campo.click
  texto.each_char do |c|
    campo.send_keys(c)
    sleep 0.3
  end
  # A lista se refaz a cada resposta do autocomplete, entao o elemento achado
  # numa iteracao pode estar obsoleto na seguinte. Achar e clicar tem que ficar
  # juntos, com nova tentativa quando o DOM trocar debaixo da mao.
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
  abort "record_select em #{campo_id}: nao consegui escolher item para #{texto.inspect}" if escolhido.nil?
  settle(driver, wait)
  escolhido
end

def selecionar(driver, id, valor)
  el = driver.find_elements(id: id).first
  return nil if el.nil?
  sel = Selenium::WebDriver::Support::Select.new(el)
  begin
    sel.select_by(:value, valor.to_s)
  rescue Selenium::WebDriver::Error::NoSuchElementError
    sel.select_by(:text, valor.to_s)
  end
  sel.first_selected_option.text.strip
end

def selecionar_texto_ou_primeiro(driver, id, preferido)
  el = driver.find_elements(id: id).first
  return nil if el.nil?
  sel = Selenium::WebDriver::Support::Select.new(el)
  begin
    sel.select_by(:text, preferido)
  rescue Selenium::WebDriver::Error::NoSuchElementError
    opcao = sel.options.find { |o| o.text.strip.length.positive? && o.attribute("value").to_s.length.positive? }
    abort "sem opcao utilizavel em #{id}" if opcao.nil?
    opcao.click
  end
  sel.first_selected_option.text.strip
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

  puts "\n1/3 matricula"
  existente = achar(driver, wait, "enrollments", NUMERO)
  if existente
    puts "  ja existe (id #{existente}) -- pulando"
  else
  driver.navigate.to("#{BASE}/enrollments/new")
  settle(driver, wait)
  driver.find_element(id: "record_enrollment_number_").send_keys(NUMERO)
  # Ha mais de um aluno com o rotulo de teste; o que interessa e o associado a
  # conta de captura, senao a tela do aluno nao mostra a matricula.
  puts "  aluno: #{record_select(driver, wait, 'record_student_', ALUNO, preferir: 'Aluno')}"
  selecionar(driver, "record_admission_date_2i", ADMISSAO.month)
  selecionar(driver, "record_admission_date_1i", ADMISSAO.year)
  # Tipo de Matricula precisa ter "Com usuario" marcado, senao o _valid_enrollment
  # nega o acesso do proprio aluno e a tela nunca chega a renderizar.
  puts "  tipo:  #{selecionar_texto_ou_primeiro(driver, 'record_enrollment_status_', 'Regular')}"
  puts "  nivel: #{selecionar_texto_ou_primeiro(driver, 'record_level_', 'Mestrado')}"
  # A data de defesa fica em branco de proposito: e ela que dispara o NameError.
  botoes = driver.find_elements(css: "form input[name='commit'], form button[name='commit']")
                 .select(&:displayed?)
  puts "  botoes de submit visiveis: #{botoes.map { |b| b.attribute('value') || b.text }.inspect}"
  abort "nenhum botao de submit visivel no formulario" if botoes.empty?
  botoes.last.click
  sleep 3
  settle(driver, wait)
  puts "  url apos gravar: #{driver.current_url}"
  # O active_scaffold deixa um painel de erro OCULTO no DOM; ler sem checar
  # visibilidade faz qualquer tela parecer quebrada.
  erro = driver.execute_script(<<~JS)
    var e = document.querySelector('.error-message, .errorExplanation, #errorExplanation, .message.error');
    return e && e.offsetParent !== null && getComputedStyle(e).display !== 'none'
      ? e.innerText.trim().slice(0, 400) : null;
  JS
    puts "  erro na tela: #{erro.inspect}" if erro
    existente = achar(driver, wait, "enrollments", NUMERO)
    abort "NAO achei #{NUMERO} -- a matricula nao foi criada" if existente.nil?
    puts "  criada (id #{existente})"
  end

  puts "\n2/3 desligamento"
  if achar(driver, wait, "dismissals", NUMERO)
    puts "  ja existe -- pulando"
  else
    driver.navigate.to("#{BASE}/dismissals/new")
    settle(driver, wait)
    puts "  matricula: #{record_select(driver, wait, 'record_enrollment_', NUMERO)}"
    selecionar(driver, "record_date_2i", DESLIGAMENTO.month)
    selecionar(driver, "record_date_1i", DESLIGAMENTO.year)
    puts "  motivo:    #{selecionar_texto_ou_primeiro(driver, 'record_dismissal_reason_', 'Titulação')}"
    driver.find_elements(css: "form input[name='commit']").select(&:displayed?).last.click
    sleep 3
    settle(driver, wait)
    puts achar(driver, wait, "dismissals", NUMERO) ? "  criado" : "  NAO confirmei o desligamento"
  end

  puts "\n3/3 banca"
  if achar(driver, wait, "thesis_defense_committee_participations", NUMERO)
    puts "  ja existe -- pulando"
  else
    driver.navigate.to("#{BASE}/thesis_defense_committee_participations/new")
    settle(driver, wait)
    puts "  matricula: #{record_select(driver, wait, 'record_enrollment_', NUMERO)}"
    puts "  professor: #{record_select(driver, wait, 'record_professor_', 'a')}"
    driver.find_elements(css: "form input[name='commit']").select(&:displayed?).last.click
    sleep 3
    settle(driver, wait)
    puts achar(driver, wait, "thesis_defense_committee_participations", NUMERO) ? "  criada" : "  NAO confirmei a banca"
  end

  id = achar(driver, wait, "enrollments", NUMERO)
  puts "\nID DA MATRICULA: #{id}  -> use no routes_aluno.txt"
ensure
  driver.quit
end
