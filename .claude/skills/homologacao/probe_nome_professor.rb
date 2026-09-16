# frozen_string_literal: true
# Sonda: propagacao de Professor#name para o nome do usuario associado.
#
# Irma do probe_nome_usuario.rb, que mede o mesmo pelo lado do aluno. Existe
# separada porque o cenario tem de ser MONTADO: a replica nao traz professor de
# teste, e o formulario de Professor nao expoe o campo de usuario -- a ligacao
# so acontece pela tela de Usuarios, num record_select.
#
#   EXPLORE_OUT=$LADO/nome_professor bundle exec ruby probe_nome_professor.rb
#   EXPLORE_OUT=$LADO/nome_professor bundle exec ruby probe_nome_professor.rb --confirmar
#
# Sem --confirmar nada e criado: so confere as precondicoes.
#
# A montagem inteira e desfeita ao fim -- professor desligado do usuario, nome
# do usuario restaurado, professor apagado. Nao e capricho: /professors esta na
# varredura estatica, e um professor a mais aparece na comparacao como
# diferenca da aplicacao quando e residuo da sonda.

require_relative "explore_common"

CONFIRMAR = ARGV.include?("--confirmar")
USER_ID = ENV.fetch("SAPOS_USER_ID_CAPTURA", "919")
MARCADOR = "ZZ-TESTE-HOMOLOG"
NOME_PROF = "#{MARCADOR} PROF"
NOME_PROF_RENOMEADO = "#{NOME_PROF} RENOMEADO"
CPF_PROF = "ZZTESTEHOMOLOGPROF"

abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 90)
relatorio = { marcador: MARCADOR, confirmar: CONFIRMAR }

def erro_visivel(driver)
  driver.execute_script(<<~JS)
    var e = document.querySelector('.error-message, .errorExplanation');
    return e && e.offsetParent !== null && getComputedStyle(e).display !== 'none'
      ? e.innerText.trim() : null;
  JS
end

begin
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")

  salvar = lambda do
    b = driver.find_element(css: "form.as_form input[type=submit]")
    driver.execute_script("arguments[0].scrollIntoView({block:'center'})", b)
    b.click
    settle(driver, wait)
    erro_visivel(driver)
  end

  # Mesma armadilha da sonda do aluno: depois de salvar, a navegacao seguinte
  # as vezes demora mais que a espera. Segunda tentativa, limite curto.
  abrir_usuario = lambda do
    2.times do |tentativa|
      driver.navigate.to("#{BASE}/users/#{USER_ID}/edit")
      settle(driver, wait)
      begin
        Selenium::WebDriver::Wait.new(timeout: 20).until do
          driver.find_elements(css: 'input[name="record[name]"]').any?
        end
        return true
      rescue Selenium::WebDriver::Error::TimeoutError
        raise if tentativa == 1
      end
    end
  end

  nome_usuario = lambda do
    abrir_usuario.call
    driver.execute_script(
      'var e = document.querySelector(\'input[name="record[name]"]\'); return e ? e.value : null;'
    )
  end

  # Professor de teste pela lista, buscando o marcador. Devolve o id ou nil.
  achar_professor = lambda do
    driver.navigate.to("#{BASE}/professors")
    settle(driver, wait)
    link = driver.find_element(css: "a.show_search")
    driver.execute_script("arguments[0].click()", link)
    wait.until { driver.find_element(css: "input[name='search']").displayed? }
    campo = driver.find_element(css: "input[name='search']")
    campo.clear
    campo.send_keys(MARCADOR)
    campo.submit
    settle(driver, wait)
    driver.execute_script(<<~JS, NOME_PROF, NOME_PROF_RENOMEADO)
      var a = arguments[0], b = arguments[1];
      var linhas = document.querySelectorAll("tr[id^='as_professors-list-']");
      for (var i = 0; i < linhas.length; i++) {
        var n = linhas[i].querySelector('td.name-column');
        var t = n ? n.innerText.trim() : '';
        if (t === a || t === b) {
          var m = /-(\\d+)-row$/.exec(linhas[i].id);
          return { id: m ? m[1] : null, nome: t };
        }
      }
      return { id: null, nome: null };
    JS
  end

  # O record_select NAO filtra com send_keys de uma vez: a requisicao sai com
  # search= vazia, a lista volta inteira, e clicar no primeiro item associa o
  # registro ERRADO em silencio. Digite caractere a caractere e espere o item.
  # O id do campo carrega o id do registro (record_professor_<id>), entao o
  # seletor estavel e a classe, nao o id.
  preencher_record_select = lambda do |css, plural, termo|
    input = driver.find_element(css: css)
    input.click
    termo.each_char do |c|
      input.send_keys(c)
      sleep 0.3
    end
    wait.until do
      driver.find_elements(css: "#record-select-#{plural} li")
        .any? { |li| li.text.to_s.include?(termo) }
    end
    alvo = driver.find_elements(css: "#record-select-#{plural} li")
      .find { |li| li.text.to_s.include?(termo) }
    driver.execute_script("arguments[0].scrollIntoView({block:'center'})", alvo)
    alvo.click
  end

  # O link de destruir existe na LISTA, nao no formulario de edicao. O
  # data-confirm sai antes do clique: dialogo nativo trava o WebDriver.
  apagar_professor = lambda do
    achar_professor.call
    clicou = driver.execute_script(<<~JS)
      var linhas = document.querySelectorAll("tr[id^='as_professors-list-']");
      for (var i = 0; i < linhas.length; i++) {
        var l = linhas[i].querySelector('a.destroy');
        if (l) { l.removeAttribute('data-confirm'); l.click(); return true; }
      }
      return false;
    JS
    settle(driver, wait)
    clicou
  end

  if ARGV.include?("--limpar")
    alvo = achar_professor.call
    if alvo["id"].nil?
      puts "nada a limpar"
    else
      # Desliga antes de apagar: professor ligado a usuario nao deve sumir com
      # o vinculo pendurado.
      abrir_usuario.call
      driver.execute_script(<<~JS)
        var h = document.querySelector('input[type=hidden][name="record[professor]"]');
        if (h) h.value = '';
      JS
      salvar.call
      apagar_professor.call
      puts "professor de teste sobrou? #{achar_professor.call["id"].inspect}"
      puts "nome do usuario agora: #{nome_usuario.call.inspect}"
    end
    exit 0
  end

  existente = achar_professor.call
  nome_usuario_inicial = nome_usuario.call
  relatorio[:precondicoes] = {
    usuario_id: USER_ID,
    nome_usuario_inicial: nome_usuario_inicial,
    professor_de_teste_preexistente: existente["id"]
  }

  unless CONFIRMAR
    relatorio[:veredito] = "diagnostico: nada foi criado"
    puts JSON.pretty_generate(relatorio)
    File.write(File.join(OUT, "probe_nome_professor.json"), JSON.pretty_generate(relatorio))
    exit 0
  end

  if existente["id"]
    abort "ABORTADO: ja existe professor de teste (id #{existente["id"]}). " \
          "Residuo de rodada anterior; limpe antes de medir."
  end

  # ---------- 1. cria o professor de teste ----------
  driver.navigate.to("#{BASE}/professors/new")
  settle(driver, wait)
  wait.until { driver.find_elements(css: 'input[name="record[name]"]').any? }
  driver.find_element(css: 'input[name="record[name]"]').send_keys(NOME_PROF)
  driver.find_element(css: 'input[name="record[cpf]"]').send_keys(CPF_PROF)
  erro_criacao = salvar.call
  criado = achar_professor.call
  abort "ABORTADO: nao criou o professor de teste (#{erro_criacao.inspect})" if criado["id"].nil?

  # ---------- 2. liga o professor a conta de captura ----------
  abrir_usuario.call
  preencher_record_select.call("input.professor-input.recordselect", "professors", NOME_PROF)
  erro_ligacao = salvar.call
  nome_usuario_apos_ligar = nome_usuario.call

  # ---------- 3. renomeia o professor e le o usuario ----------
  driver.navigate.to("#{BASE}/professors/#{criado["id"]}/edit")
  settle(driver, wait)
  wait.until { driver.find_elements(css: 'input[name="record[name]"]').any? }
  campo = driver.find_element(css: 'input[name="record[name]"]')
  campo.clear
  campo.send_keys(NOME_PROF_RENOMEADO)
  erro_rename = salvar.call
  shot(driver, "professor_apos_renomear")
  nome_usuario_apos_renomear = nome_usuario.call

  relatorio[:ciclo] = {
    professor_id: criado["id"],
    nome_usuario_inicial: nome_usuario_inicial,
    nome_usuario_apos_ligar: nome_usuario_apos_ligar,
    propagou_na_ligacao: nome_usuario_apos_ligar == NOME_PROF,
    nome_usuario_apos_renomear: nome_usuario_apos_renomear,
    propagou_na_renomeacao: nome_usuario_apos_renomear == NOME_PROF_RENOMEADO,
    erro_na_criacao: erro_criacao,
    erro_na_ligacao: erro_ligacao,
    erro_no_rename: erro_rename
  }

  # ---------- 4. desfaz: desliga, restaura o nome, apaga ----------
  # A ordem importa: enquanto o professor estiver ligado, restaurar o nome do
  # usuario seria desfeito pela propagacao seguinte.
  abrir_usuario.call
  driver.execute_script(<<~JS)
    var h = document.querySelector('input[type=hidden][name="record[professor]"]');
    if (h) h.value = '';
  JS
  erro_desligar = salvar.call

  abrir_usuario.call
  campo = driver.find_element(css: 'input[name="record[name]"]')
  campo.clear
  campo.send_keys(nome_usuario_inicial)
  erro_restaurar = salvar.call
  nome_usuario_final = nome_usuario.call

  apagou = apagar_professor.call
  sobrou = achar_professor.call

  relatorio[:limpeza] = {
    nome_usuario_final: nome_usuario_final,
    usuario_restaurado: nome_usuario_final == nome_usuario_inicial,
    clicou_em_apagar: apagou,
    professor_sobrou: sobrou["id"],
    limpo: sobrou["id"].nil? && nome_usuario_final == nome_usuario_inicial,
    erro_ao_desligar: erro_desligar,
    erro_ao_restaurar: erro_restaurar
  }

  relatorio[:console] = console_severe(driver)
ensure
  driver.quit
end

puts JSON.pretty_generate(relatorio)
File.write(File.join(OUT, "probe_nome_professor.json"), JSON.pretty_generate(relatorio))
