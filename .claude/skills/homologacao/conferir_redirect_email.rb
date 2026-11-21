# frozen_string_literal: true

# Le o valor VIVO de CustomVariable.redirect_email na tela de Variaveis e diz em
# qual dos tres estados da tabela verdade do SKILL.md a replica esta. E o passo 0
# de qualquer escrita em homologacao, e nao substitui a leitura pela tela quando
# o resultado for PERIGO -- ai a decisao e do mantenedor.
#
#   EXPLORE_OUT=$LADO/escrita bundle exec ruby conferir_redirect_email.rb
#
# SO LEITURA. Nao imprime o endereco inteiro: so o dominio, que basta para
# reconhecer o alias de teste sem copiar dado de contato para o terminal.
require_relative "explore_common"

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 30)
begin
  login(driver, wait)
  # Logo depois de reimportar a replica a conta tem um papel so, e o combo so
  # aparece com dois -- quem acrescenta o segundo e o preparar_aluno_de_teste.rb,
  # que ja escreve e por isso vem depois deste script.
  combo = driver.find_elements(css: "form[action*='change_role'] select[name='role_id']")
  switch_role!(driver, wait, "Administrador") if combo.any?
  driver.navigate.to("#{BASE}/custom_variables?per_page=200")
  settle(driver, wait)

  linhas = driver.execute_script(<<~JS)
    return Array.from(document.querySelectorAll("tr.record")).map(function (tr) {
      return Array.from(tr.querySelectorAll("td")).map(function (td) { return td.innerText.trim(); });
    });
  JS
  # Lista vazia e "nao li", nao "variavel ausente": papel sem acesso a tela
  # devolve zero linhas, e isso se leria como PERIGO.
  if linhas.empty?
    puts "Tela de Variaveis sem linhas (papel ativo: #{papel_ativo(driver).inspect}). Medida recusada."
    exit 3
  end
  alvo = linhas.find { |cells| cells.any? { |c| c == "redirect_email" } }

  if alvo.nil?
    puts "redirect_email: AUSENTE -> nil -> PERIGO: envia ao destinatario real. Nao dispare nada."
    exit 2
  end
  idx = alvo.index("redirect_email")
  valor = alvo[idx + 1].to_s
  if valor.empty? || valor == "-" || valor == "–"
    puts "redirect_email: presente e VAZIA -> \"\" -> trava mestra, nada envia."
    exit 0
  end
  dominio = valor.split("@").last
  puts "redirect_email: presente com ENDERECO (@#{dominio}) -> redireciona tudo para ele."
  exit 1
ensure
  driver.quit
end
