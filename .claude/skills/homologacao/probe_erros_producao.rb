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
# NAO ESCREVE. O POST do CSRF e recusado antes de tocar em registro; a medida do
# campo composto nao submete (dispatchEvent de "submit" roda os handlers e nao
# envia o formulario).
#
# O fluxo publico de inscricao nao esta aqui: ele exige abrir um processo
# seletivo, que e escrita, e mora no abrir_processo_seletivo.rb.

require_relative "explore_common"

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 60)

# O papel ativo atravessa execucoes, e a captura do aluno costuma ser a ultima.
# Sem isto a sonda navega como aluno e nao acha nada -- e o sintoma mente.
begin
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")

  puts "\n=== token de CSRF que nao bate ==="
  # Tres cenarios levantam a MESMA excecao e devem ter respostas diferentes.
  # Separa-los exige cuidado com duas armadilhas:
  #
  # 1. Abrir a pagina de login JA CRIA sessao, com _csrf_token dentro. Estragar
  #    o campo do formulario produz "sessao viva com token que nao bate", nao
  #    expiracao. Para reproduzir a expiracao e preciso apagar os cookies.
  # 2. Nao meca por fetch: ele manda Accept "*/*", que o Rails nao trata como
  #    HTML, e a resposta cai no ramo nao-navegacional (422 sem corpo). O que o
  #    usuario ve so aparece submetendo formulario de verdade.
  def aviso_na_tela(driver)
    driver.find_element(css: "body").text.to_s.lines.map(&:strip).find do |l|
      l.include?("sessão expirou") || l.include?("confirmar o envio") ||
        l.include?("rejeitada") || l.include?("já está logado")
    end
  end

  # Sair antes: com a sessao de admin viva, /users/sign_in desvia e nem existe
  # campo de e-mail para preencher.
  driver.manage.delete_all_cookies
  driver.navigate.to("#{BASE}/users/sign_in")
  settle(driver, wait)
  # Agora sim: a pagina rendeu o formulario e criou sessao; apagar o cookie
  # aqui deixa o token do formulario sem sessao com que casar, que e o que a
  # expiracao faz na pratica.
  driver.manage.delete_all_cookies
  driver.find_element(id: "user_email").send_keys("ninguem@example.invalid")
  driver.find_element(id: "user_password").send_keys("qualquer-coisa")
  driver.find_element(id: "user_password").submit
  sleep 3
  puts "  sem sessao   -> #{driver.current_url.split("/").last}: #{aviso_na_tela(driver).inspect}"

  login(driver, wait)
  origem = driver.current_url
  # /enrollment_holds e um POST comum de quem esta logado, e o pedido morre na
  # checagem de CSRF, sem criar registro nenhum.
  driver.execute_script(<<~JS)
    var f = document.createElement("form");
    f.method = "post";
    f.action = "#{BASE}/enrollment_holds";
    var t = document.createElement("input");
    t.type = "hidden"; t.name = "authenticity_token"; t.value = "adulterado";
    f.appendChild(t);
    document.body.appendChild(f);
    f.submit();
  JS
  sleep 3
  puts "  sessao viva  -> #{aviso_na_tela(driver).inspect}"
  puts "  voltou para a origem? #{driver.current_url == origem ? 'sim' : 'nao'}"
  console_severe(driver)

  puts "\n=== campo composto de cidade ==="
  # A estatica NAO vota aqui: o composto so se monta depois de preencher os
  # campos visiveis, e nenhuma rota da varredura faz isso.
  #
  # O que o servidor valida e o input escondido, nao os visiveis. A medida poe
  # valor nos visiveis SEM disparar evento -- e o que autofill, gerenciador de
  # senha e script fazem -- e confere se o escondido acompanhou.
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
