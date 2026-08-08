#!/usr/bin/env ruby
# frozen_string_literal: true

# Sonda os defeitos de producao que a varredura estatica nao alcanca, porque
# nenhum deles e um GET simples: um exige POST e o outro so aparece depois de
# preencher um widget.
#
# Rode nos DOIS lados da rodada, antes e depois do deploy, e compare a saida.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   EXPLORE_OUT=~/capturas-sapos-staging/<pasta>/sonda \
#     bundle exec ruby probe_erros_producao.rb
#
# NAO ESCREVE. O fluxo 1 tem o POST recusado antes de tocar em registro; o fluxo
# 2 mede o campo escondido sem submeter (dispatchEvent de "submit" roda os
# handlers e nao envia o formulario).
#
# O QUE ESTA SONDA NAO COBRE, e por que: a submissao sem o parametro `record` no
# apply do candidato precisa de processo seletivo ABERTO e de um token de
# inscricao real -- sem os dois, o pedido para antes, no
# check_if_process_is_open_to_edit, e a sonda mediria outra coisa. A evidencia
# desse caso fica nos request specs. Se um dia houver processo aberto na
# replica, vale acrescentar o fluxo aqui.

require_relative "explore_common"

driver = build_driver
driver.manage.timeouts.script_timeout = 30 # o fluxo 1 usa execute_async_script
wait = Selenium::WebDriver::Wait.new(timeout: 60)

# O papel ativo atravessa execucoes, e a captura do aluno costuma ser a ultima.
# Sem isto a sonda navega como aluno e nao acha nada -- e o sintoma mente.
begin
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")

  puts "\n=== fluxo 1: token de CSRF que nao bate (item 2) ==="
  # Ate 7.15.29 o usuario recebia a pagina estatica de 422, que fala em falta de
  # permissao, e o erro virava e-mail para a lista. Depois: volta ao login com
  # "sua sessao expirou", e so notifica quando a sessao tem conteudo.
  # NAO poste em /users/sign_in: o require_no_authentication do Devise e
  # prependado depois do verify_authenticity_token e desvia o usuario logado
  # antes da checagem de CSRF -- a sonda mediria o desvio, nao o token.
  # /enrollment_holds e um POST comum de quem esta logado, e o pedido morre na
  # checagem de CSRF, sem criar registro nenhum.
  resultado = driver.execute_async_script(<<~JS)
    var done = arguments[0];
    var body = new URLSearchParams({
      "authenticity_token": "token-que-nao-bate",
      "commit": "Criar"
    });
    fetch("#{BASE}/enrollment_holds", {
      method: "POST", body: body, redirect: "follow",
      headers: {"Content-Type": "application/x-www-form-urlencoded"}
    }).then(function(r) {
      return r.text().then(function(t) {
        done({status: r.status, url: r.url, trecho: t.slice(0, 600)});
      });
    }).catch(function(e) { done({erro: String(e)}); });
  JS
  texto = resultado["trecho"].to_s
  puts "  status: #{resultado['status']}"
  puts "  url final: #{resultado['url']}"
  puts "  anuncia sessao expirada? #{texto.downcase.include?('sess') ? 'sim' : 'nao'}"
  puts "  pagina generica de rejeicao? #{texto.include?('rejeitada') ? 'sim' : 'nao'}"
  console_severe(driver)

  puts "\n=== fluxo 2: campo composto de cidade (item 3) ==="
  # A estatica NAO vota aqui: o composto so se monta depois de preencher os
  # campos visiveis, e nenhuma rota da varredura faz isso. Ate 7.15.29, valor
  # que entrava sem disparar evento nao chegava ao escondido, e quem preenchia
  # recebia "nao pode ficar em branco" num campo preenchido na tela.
  #
  # Mede na tela do admin porque a replica nao tem processo seletivo aberto: o
  # widget e o mesmo parcial do formulario publico do candidato.
  # Ordenar por id decrescente: o campo de cidade e do formulario dos processos
  # recentes, e a ordem natural da lista traz inscricoes antigas, sem ele.
  LISTA = "#{BASE}/admission_applications?sort=id&sort_direction=DESC"
  driver.navigate.to(LISTA)
  settle(driver, wait)
  ids = driver.page_source.scan(%r{/admission_applications/(\d+)}).flatten.uniq
  puts "  inscricoes candidatas (mais recentes): #{ids.size}"

  medido = false
  ids.each do |id|
    # Chegar pelo link da lista, e nao pela rota /edit: navegar direto monta a
    # tela sem o que o JS do active_scaffold precisa, e o formulario nem aparece.
    driver.navigate.to(LISTA)
    settle(driver, wait)
    # O prefixo carrega o namespace: as_admissions__admission_applications-.
    # Sem ele o find nao casa com nada, e o laco passa por todas as inscricoes
    # em silencio, terminando num "PULADO" que parece falta de campo de cidade.
    link = driver.find_elements(
      id: "as_admissions__admission_applications-edit-#{id}-link"
    ).first
    next if link.nil?
    # Os links de acao vivem num menu que so se abre no hover: clicar direto
    # devolve "element not interactable". Clique por JS resolve sem depender de
    # abrir o menu.
    driver.execute_script("arguments[0].click()", link)
    settle(driver, wait)
    sleep 2
    next if driver.find_elements(css: "input[name='city']").empty?

    valor = driver.execute_script(<<~JS)
      var dd = document.querySelector("input[name='city']").closest(".city-fields");
      if (!dd) { return "SEM_CONTAINER"; }
      dd.querySelector("input[name='country']").value = "ZZBrasil";
      dd.querySelector("input[name='state']").value = "ZZRJ";
      dd.querySelector("input[name='city']").value = "ZZNiteroi";
      dd.closest("form").dispatchEvent(new Event("submit", {cancelable: true}));
      return dd.querySelector("input.hidden").value;
    JS
    puts "  inscricao #{id}: escondido apos o submit = #{valor.inspect}"
    puts "  acompanhou a tela? #{valor.to_s.include?('ZZNiteroi') ? 'sim' : 'NAO'}"
    shot(driver, "cidade_inscricao_#{id}")
    medido = true
    break
  end
  puts "  PULADO: nenhuma das #{ids.size} inscricoes renderizou campo de cidade" unless medido
  console_severe(driver)
ensure
  driver.quit
end
