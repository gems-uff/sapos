# frozen_string_literal: true
# Processo com require_session so deixa abrir a inscricao no navegador que a
# recuperou, e a prova disso e o token guardado em session[:admission_tokens].
# O add_token_to_session cria a chave no topo na primeira vez e daí em diante
# muta o Set em lugar -- a mesma forma de escrita que o active_scaffold usa para
# a busca. Enquanto a sessao nao enxergava mutacao em lugar, so o PRIMEIRO token
# sobrevivia, e o candidato que recuperava uma segunda inscricao no mesmo
# navegador levava "acesso nao autorizado" numa inscricao que acabara de
# recuperar.
#
#   EXPLORE_OUT=$LADO/tokens bundle exec ruby probe_tokens_admissao.rb
#
# SO LEITURA: recuperar inscricao nao altera a candidatura, so a sessao. Nao
# cria, nao apaga e nao envia e-mail (o fluxo de recuperacao por token nao
# dispara mensagem; ainda assim confira redirect_email antes, por regra).
#
# DADO REAL: usa duas candidaturas existentes da replica. Token e e-mail sao
# lidos da tela e ficam SO em memoria -- o relatorio guarda booleanos e rotulos
# genericos ("A", "B"), nunca o valor. Nao tira screenshot por isso.
#
# A medida decisiva e a SEGUNDA recuperacao: o proprio redirect que a segue ja e
# uma requisicao nova, que le a sessao do banco. Se a gravacao da segunda se
# perdeu, ele desvia ali mesmo.
#
# BLOQUEIO CONHECIDO: a homologacao roda em ambiente production, e ali
# `should_use_recaptcha` e true. O #find valida o reCAPTCHA antes de procurar a
# inscricao, entao Selenium headless nao passa: a tela volta com "reCAPTCHA
# invalido" e NENHUM token entra na sessao. A sonda detecta isso e recusa a
# medida -- sem essa deteccao o resultado seria "desviou em tudo", que se leria
# como defeito da aplicacao. Para medir de verdade e preciso que a instancia
# esteja com should_use_recaptcha desligado; e decisao do mantenedor.
#
# Cuidado ao depurar: quando o #find recusa, o redirect devolve token e e-mail
# do candidato na QUERY STRING. Nao imprima nem guarde a URL desta tela.

# O processo TEM de ter require_session ligado, senao a tela abre para qualquer
# navegador e a sonda mede o nada. A replica tem processos dos dois tipos, e a
# coluna nao aparece na lista -- por isso o processo vem fixado aqui, e o passo
# de controle confere que a trava esta mesmo ativa antes de valer a medida.
PROCESSO_NOME = ENV.fetch("SAPOS_PROCESSO_TOKENS_NOME", "Doutorado 2025/1")
PROCESSO_URL = ENV.fetch("SAPOS_PROCESSO_TOKENS_URL", "doutorado-2025-1")

require_relative "explore_common"

wait = Selenium::WebDriver::Wait.new(timeout: 30)
driver = build_driver
relatorio = { passos: [] }

# O formulario de recuperacao nasce OCULTO atras do link "Mostrar" -- os campos
# existem no DOM desde o inicio, entao esperar por presenca passa e o send_keys
# estoura com "element not interactable". A espera tem de ser por visibilidade.
def recuperar(driver, wait, token, email)
  driver.navigate.to("#{BASE}/admissions")
  settle(driver, wait)
  visivel = lambda do
    driver.execute_script(
      "var e = document.querySelector('#recover-email'); return !!e && e.offsetParent !== null;"
    )
  end
  driver.find_elements(link_text: "Mostrar").first&.click unless visivel.call
  wait.until { visivel.call }

  driver.find_element(css: "input[name='admissions_admission_application[email]']").send_keys(email)
  campo = driver.find_element(css: "input[name='admissions_admission_application[token]']")
  campo.send_keys(token)
  marcar_recaptcha(driver, wait)
  campo.submit
  settle(driver, wait)
  # A pagina de recusa monta a mensagem depois do settle; sem esta folga a
  # deteccao do reCAPTCHA le o corpo antigo e a medida passa por defeito da
  # aplicacao.
  sleep 2
end

# "Desviou" e o veredito: negado, o controller manda para /admissions. NAO
# procure elemento de alerta -- a mensagem sai no corpo da pagina, sem classe
# de alerta nenhuma, e um seletor de .alert devolve false em todo caso, o que
# faria a sonda dizer "abriu" mesmo quando a tela foi negada.
def desviou?(driver)
  driver.current_url.split("?").first.end_with?("/admissions")
end

# "No CAPTCHA" das chaves de teste quer dizer sem DESAFIO de imagem, nao sem
# clique: o widget ainda nasce desmarcado e o campo g-recaptcha-response fica
# VAZIO ate alguem marcar a caixa. Submeter sem marcar e recusado igual, e o
# sintoma ("reCAPTCHA invalido") e o mesmo de chave errada -- o que faz perder
# tempo procurando no servidor um defeito que esta na sonda.
#
# A caixa vive dentro do iframe do Google; marcar exige entrar nele e voltar.
# Quando nao ha widget na pagina (instancia com o captcha desligado por
# configuracao), nao ha nada a fazer e a funcao sai calada.
def marcar_recaptcha(driver, wait)
  frame = driver.find_elements(css: "iframe[src*='recaptcha/api2/anchor']").first
  return if frame.nil?

  driver.switch_to.frame(frame)
  begin
    caixa = wait.until { driver.find_elements(css: "#recaptcha-anchor, .recaptcha-checkbox").first }
    caixa.click
  ensure
    driver.switch_to.default_content
  end
  Selenium::WebDriver::Wait.new(timeout: 20).until do
    driver.execute_script(
      "var f = document.querySelector('[name=\"g-recaptcha-response\"]');" \
      "return f ? f.value.length > 0 : true;"
    )
  end
end

def recaptcha_barrou?(driver)
  driver.execute_script(
    "return /reCAPTCHA/i.test(document.body.innerText);"
  )
end

# `exit` aqui dentro estoura SystemExit atraves do ensure e imprime backtrace
# num desfecho que e normal. O catch devolve o controle limpo.
catch(:recusar) do
begin
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")

  driver.navigate.to("#{BASE}/admission_applications")
  settle(driver, wait)
  sleep 2
  # [token, email] das duas primeiras candidaturas com os dois campos
  # preenchidos. Ficam em memoria; nada disso vai para o relatorio.
  pares = driver.execute_script(<<~JS, PROCESSO_NOME)
    var processo = arguments[0];
    return Array.from(document.querySelectorAll("tbody tr")).map(function (tr) {
      var c = tr.querySelectorAll("td");
      if (c.length < 4) return null;
      if (c[0].innerText.indexOf(processo) < 0) return null;
      var token = c[1].innerText.trim(), email = c[3].innerText.trim();
      return (token && email && email.indexOf("@") > 0) ? [token, email] : null;
    }).filter(Boolean);
  JS
  pares = pares.uniq { |(_, email)| email }
  if pares.size < 2
    abort "Menos de duas candidaturas em #{PROCESSO_NOME.inspect} com token e e-mail distintos."
  end
  a, b = pares[0], pares[1]
  url_b = "#{BASE}/admissions/#{PROCESSO_URL}/apply/#{b[0]}"

  # CONTROLE PRIMEIRO: sem ter recuperado nada, a tela de B tem de ser negada.
  # Se ela abrir, o processo esta sem require_session e o exemplar nao tem o
  # caso -- a medida seguinte diria "abriu" nos dois lados, e isso se leria como
  # correcao funcionando. Por isso a sonda RECUSA a medida em vez de reportar.
  driver.manage.delete_all_cookies
  driver.navigate.to(url_b)
  settle(driver, wait)
  guarda_ativa = desviou?(driver)
  relatorio[:passos] << { passo: "controle: abrir B sem ter recuperado", desviou: guarda_ativa }
  puts "  controle (sem recuperar)     desviou=#{guarda_ativa}"

  unless guarda_ativa
    relatorio[:medida_recusada] =
      "A tela de B abriu sem sessao: o processo #{PROCESSO_NOME} esta sem " \
      "require_session, entao nao ha trava para medir. Escolha outro processo."
    puts "MEDIDA RECUSADA: #{relatorio[:medida_recusada]}"
    throw :recusar
  end

  # Sessao publica limpa: o defeito e sobre o que atravessa requisicoes.
  driver.manage.delete_all_cookies

  recuperar(driver, wait, a[0], a[1])
  if recaptcha_barrou?(driver)
    relatorio[:medida_recusada] =
      "O #find foi barrado pelo reCAPTCHA (should_use_recaptcha ligado nesta " \
      "instancia). Nenhum token entra na sessao, entao nao ha o que medir."
    puts "MEDIDA RECUSADA: #{relatorio[:medida_recusada]}"
    throw :recusar
  end
  desviou_a = desviou?(driver)
  relatorio[:passos] << { passo: "recuperar a inscricao A", desviou: desviou_a }
  puts "  recuperar A                  desviou=#{desviou_a}"

  recuperar(driver, wait, b[0], b[1])
  desviou_b = desviou?(driver)
  relatorio[:passos] << { passo: "recuperar a inscricao B (a medida)", desviou: desviou_b }
  puts "  recuperar B (a medida)       desviou=#{desviou_b}"

  relatorio[:veredito] = {
    guarda_ativa: guarda_ativa,
    primeira_recuperacao_abriu: !desviou_a,
    segunda_recuperacao_abriu: !desviou_b,
    ok: guarda_ativa && !desviou_a && !desviou_b
  }
  relatorio[:erros_console] = console_severe(driver)
ensure
  driver&.quit
end
end

saida = File.join(OUT, "probe_tokens_admissao.json")
File.write(saida, JSON.pretty_generate(relatorio))
puts "\nveredito: #{(relatorio[:veredito] || relatorio[:medida_recusada]).inspect}"
puts "relatorio: #{saida}"
