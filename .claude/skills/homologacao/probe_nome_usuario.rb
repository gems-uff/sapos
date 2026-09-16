# frozen_string_literal: true
# Sonda: propagacao do nome do registro para o nome do usuario associado.
#
# A varredura estatica NAO vota aqui. Ela carrega rota, tira foto e le texto --
# e o que esta sob medida e um caminho de ESCRITA, que ela nao exercita. Sem
# esta sonda a rodada devolveria "sem diferenca" por nao ter medido nada, que se
# le como "nao regrediu".
#
#   EXPLORE_OUT=$LADO/nome_usuario bundle exec ruby probe_nome_usuario.rb
#   EXPLORE_OUT=$LADO/nome_usuario bundle exec ruby probe_nome_usuario.rb --confirmar
#
# Sem --confirmar nada e alterado: le o estado e confere as precondicoes, que e
# o que diz se a medida vale. Com --confirmar renomeia o aluno de teste, le o
# nome do usuario e RESTAURA o nome original -- o lado volta como comecou.
#
# O usuario medido e a propria conta de captura: o preparar_aluno_de_teste.rb
# associa a conta ao aluno de teste e poe o e-mail dela no aluno. E por esse
# e-mail que a sonda amarra os dois, e ela RECUSA a medida se nao casar --
# medir um par que nao esta ligado devolveria "nao propagou" nos dois lados.

require_relative "explore_common"

CONFIRMAR = ARGV.include?("--confirmar")
# Muda a cada regeracao da replica; ache pela lista de Alunos buscando o
# marcador, ou passe SAPOS_ALUNO_TESTE.
ALUNO_TESTE = ENV.fetch("SAPOS_ALUNO_TESTE", "2258")
MARCADOR = "ZZ-TESTE-HOMOLOG"
SUFIXO = " RENOMEADO"

abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 90)
relatorio = { marcador: MARCADOR, confirmar: CONFIRMAR }

# O active_scaffold deixa no DOM, OCULTO, um painel "Internal Error". Ler o
# innerText sem checar visibilidade faz qualquer pagina parecer quebrada.
def erro_visivel(driver)
  driver.execute_script(<<~JS)
    var e = document.querySelector('.error-message, .errorExplanation');
    return e && e.offsetParent !== null && getComputedStyle(e).display !== 'none'
      ? e.innerText.trim() : null;
  JS
end

begin
  login(driver, wait)
  # O papel ativo fica gravado no usuario e atravessa execucoes: sem isto a
  # sonda pode herdar o papel Aluno da ultima captura e nao achar tela nenhuma.
  switch_role!(driver, wait, "Administrador")

  # Depois de salvar, o navegador as vezes fica preso na saida da pagina (o
  # console registra o "beforeunload" bloqueado) e a navegacao seguinte demora
  # mais que a espera. Uma segunda tentativa resolve, e o limite continua curto:
  # espera longa aqui esconde pagina que nao montou.
  abrir_aluno = lambda do
    2.times do |tentativa|
      driver.navigate.to("#{BASE}/students/#{ALUNO_TESTE}/edit")
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

  estado_aluno = lambda do
    driver.execute_script(<<~JS)
      return {
        nome: (document.querySelector('input[name="record[name]"]') || {}).value,
        email: (document.querySelector('input[name="record[email]"]') || {}).value
      };
    JS
  end

  salvar = lambda do
    b = driver.find_element(css: "form.as_form input[type=submit]")
    driver.execute_script("arguments[0].scrollIntoView({block:'center'})", b)
    b.click
    settle(driver, wait)
    erro_visivel(driver)
  end

  # Nome do usuario pela lista de Usuarios, buscando pelo e-mail. A lista mostra
  # e-mail, nome e papeis, entao o nome se le sem abrir o formulario.
  ler_usuario = lambda do
    driver.navigate.to("#{BASE}/users")
    settle(driver, wait)
    # O campo de busca so existe depois do clique no link "Buscar", que o
    # active_scaffold renderiza com a classe show_search.
    link = driver.find_element(css: "a.show_search")
    driver.execute_script("arguments[0].click()", link)
    wait.until { driver.find_element(css: "input[name='search']").displayed? }
    campo = driver.find_element(css: "input[name='search']")
    campo.clear
    campo.send_keys(USER)
    campo.submit
    settle(driver, wait)
    driver.execute_script(<<~JS, USER)
      var alvo = arguments[0].toLowerCase();
      var linhas = document.querySelectorAll("tr[id^='as_users-list-']");
      for (var i = 0; i < linhas.length; i++) {
        var email = linhas[i].querySelector('td.email-column');
        if (email && email.innerText.trim().toLowerCase() === alvo) {
          var nome = linhas[i].querySelector('td.name-column');
          // \\d, nao \d: heredoc do Ruby come a barra de escape desconhecida,
          // e /-(d+)-row$/ nunca casa -- user_id sairia nil e a restauracao do
          // nome do usuario, adiante, nao dispararia.
          var m = /-(\\d+)-row$/.exec(linhas[i].id);
          return { id: linhas[i].id, user_id: m ? m[1] : null,
                   nome: nome ? nome.innerText.trim() : null };
        }
      }
      return { id: null, nome: null, linhas: linhas.length };
    JS
  end

  abrir_aluno.call
  inicial = estado_aluno.call
  usuario_inicial = ler_usuario.call

  relatorio[:precondicoes] = {
    aluno_id: ALUNO_TESTE,
    aluno_e_o_de_teste: inicial["nome"].to_s.include?(MARCADOR),
    email_do_aluno_casa_com_a_conta:
      inicial["email"].to_s.strip.casecmp?(USER.to_s.strip),
    usuario_encontrado: !usuario_inicial["id"].nil?
  }
  relatorio[:nome_aluno_inicial] = inicial["nome"]
  relatorio[:nome_usuario_inicial] = usuario_inicial["nome"]

  unless relatorio[:precondicoes].values_at(
    :aluno_e_o_de_teste, :email_do_aluno_casa_com_a_conta, :usuario_encontrado
  ).all?
    relatorio[:veredito] = "MEDIDA RECUSADA: precondicao falhou; nada foi alterado"
    puts JSON.pretty_generate(relatorio)
    File.write(File.join(OUT, "probe_nome_usuario.json"), JSON.pretty_generate(relatorio))
    exit 1
  end

  if CONFIRMAR
    original = inicial["nome"]
    novo = original.end_with?(SUFIXO) ? original.sub(/#{Regexp.escape(SUFIXO)}\z/, "") : original + SUFIXO

    # ler_usuario deixou o navegador na lista de Usuarios.
    abrir_aluno.call
    campo = driver.find_element(css: 'input[name="record[name]"]')
    campo.clear
    campo.send_keys(novo)
    erro_rename = salvar.call
    shot(driver, "apos_renomear")

    abrir_aluno.call
    aluno_depois = estado_aluno.call
    usuario_depois = ler_usuario.call

    # Restaura, e no lado "depois" a restauracao tambem propaga de volta.
    abrir_aluno.call
    campo = driver.find_element(css: 'input[name="record[name]"]')
    campo.clear
    campo.send_keys(original)
    erro_restore = salvar.call
    abrir_aluno.call
    aluno_restaurado = estado_aluno.call
    usuario_restaurado = ler_usuario.call

    relatorio[:ciclo] = {
      nome_aluno_original: original,
      nome_aluno_apos_renomear: aluno_depois["nome"],
      renomeacao_persistiu: aluno_depois["nome"] == novo,
      nome_usuario_apos_renomear: usuario_depois["nome"],
      propagou: usuario_depois["nome"] == novo,
      nome_aluno_restaurado: aluno_restaurado["nome"],
      voltou_ao_estado_inicial: aluno_restaurado["nome"] == original,
      nome_usuario_apos_restaurar: usuario_restaurado["nome"],
      erro_no_rename: erro_rename,
      erro_na_restauracao: erro_restore
    }

    # A propagacao SOBRESCREVE o nome do usuario, entao restaurar o nome do
    # aluno nao devolve o do usuario: ele fica com o nome do aluno. Sem desfazer
    # isto, o nome novo aparece em toda tela que lista usuario ou autoria, e a
    # comparacao acusa diferenca que e da sonda, nao da aplicacao.
    nome_usuario_alvo = ENV.fetch("SAPOS_NOME_USUARIO_ORIGINAL", usuario_inicial["nome"])
    if usuario_restaurado["nome"] != nome_usuario_alvo && usuario_restaurado["user_id"]
      driver.navigate.to("#{BASE}/users/#{usuario_restaurado["user_id"]}/edit")
      settle(driver, wait)
      wait.until { driver.find_elements(css: 'input[name="record[name]"]').any? }
      campo = driver.find_element(css: 'input[name="record[name]"]')
      campo.clear
      campo.send_keys(nome_usuario_alvo)
      erro_usuario = salvar.call
      final = ler_usuario.call
      relatorio[:restauracao_do_usuario] = {
        alvo: nome_usuario_alvo,
        nome_final: final["nome"],
        restaurou: final["nome"] == nome_usuario_alvo,
        erro: erro_usuario
      }
    end
  end

  relatorio[:console] = console_severe(driver)
ensure
  driver.quit
end

puts JSON.pretty_generate(relatorio)
File.write(File.join(OUT, "probe_nome_usuario.json"), JSON.pretty_generate(relatorio))
