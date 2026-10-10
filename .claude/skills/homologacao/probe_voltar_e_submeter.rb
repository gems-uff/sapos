# frozen_string_literal: true

# Mede o bug de navegador que o autocomplete="off" nos hidden contornava: ao
# voltar (history.back) a uma pagina com formulario, o Firefox restaurava valor
# velho no PRIMEIRO campo escondido -- authenticity_token ou _method --, e a
# submissao seguinte caia em InvalidAuthenticityToken. O Rails 8.1 deixa de
# emitir o atributo; esta sonda diz se o efeito aparece AQUI, no navegador
# escolhido por SELENIUM_BROWSER.
#
#   EXPLORE_OUT=$LADO/voltar SELENIUM_BROWSER=firefox bundle exec ruby probe_voltar_e_submeter.rb [n]
#
# SO LEITURA, sem login: usa o formulario de /users/sign_in com e-mail que nao
# existe -- nada grava (trackable so grava em sucesso) e nada trava (lockable
# conta tentativas por conta, e a conta nao existe). Repete n vezes (default 10)
# porque o bug era esporadico.
#
# O que se compara entre os lados e o par (hidden_alterado, reacao). A reacao
# "token invalido" e a mensagem errors.invalid_form_token; a normal e a recusa
# de credencial do Devise.
require_relative "explore_common"

n = (ARGV[0] || "10").to_i
driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 30)
ler_hidden = "return Array.from(document.querySelectorAll('form#login_form input[type=hidden]')).map(i => [i.name, i.value, i.getAttribute('autocomplete')]);"
rodadas = []
begin
  n.times do |i|
    driver.navigate.to("#{BASE}/users/sign_in")
    wait.until { driver.find_element(id: "user_email") }
    antes = driver.execute_script(ler_hidden)
    driver.navigate.to("#{BASE}/users/password/new")
    wait.until { driver.current_url.include?("password") }
    driver.navigate.back
    wait.until { driver.current_url.include?("sign_in") && driver.find_element(id: "user_email") }
    depois = driver.execute_script(ler_hidden)
    alterado = antes.map { |x| x[0, 2] } != depois.map { |x| x[0, 2] }

    driver.find_element(id: "user_email").send_keys("zz-teste-homolog-inexistente-#{i}@example.invalid")
    campo = driver.find_element(id: "user_password"); campo.send_keys("nao-e-senha"); campo.submit
    # A resposta do POST chega depois do submit; ler o corpo antes dela mede a
    # pagina anterior. Espera a mensagem -- qualquer das tres -- ou desiste.
    corpo = begin
      wait.until do
        c = driver.execute_script("return document.body.innerText;").to_s
        c if c =~ /confirmar o envio deste formul|sessão expirou|inválid|incorret/i
      end
    rescue Selenium::WebDriver::Error::TimeoutError
      "SEM RESPOSTA EM 30s: " + driver.execute_script("return document.body.innerText;").to_s
    end
    reacao = case corpo
             when /confirmar o envio deste formul/i then "token_invalido"
             when /sessão expirou/i then "sessao_expirada"
             when /inválid|incorret|invalid/i then "credencial_recusada (normal)"
             else "outra: #{corpo.gsub(/\s+/, ' ')[0, 120].inspect}"
             end
    rodadas << { rodada: i + 1, hidden_antes: antes.map { |x| [x[0], x[2]] }, hidden_alterado_ao_voltar: alterado, reacao: reacao }
    puts format("%2d/%d hidden alterado ao voltar: %-5s reacao: %s", i + 1, n, alterado, reacao)
  end
ensure
  driver.quit
end
resumo = { navegador: NAVEGADOR, rodadas: rodadas.size,
           hidden_no_form: rodadas.first&.dig(:hidden_antes),
           alterados: rodadas.count { |r| r[:hidden_alterado_ao_voltar] },
           reacoes: rodadas.group_by { |r| r[:reacao] }.transform_values(&:size),
           detalhe: rodadas }
File.write(File.join(OUT, "probe_voltar_e_submeter.json"), JSON.pretty_generate(resumo))
puts "\nresumo: #{resumo.except(:detalhe).to_json}"
puts "json: #{File.join(OUT, 'probe_voltar_e_submeter.json')}"
