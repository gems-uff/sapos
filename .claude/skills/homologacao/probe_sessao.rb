# frozen_string_literal: true
# Mede o que a varredura estatica nao alcanca: estado que atravessa requisicoes
# dentro de uma sessao. Cada rota da varredura e um GET novo, entao filtro que
# se perde entre uma requisicao e a seguinte passa por ela sem um pixel de
# diferenca.
#
# O que se mede aqui e a TROCA de filtro. Sob um filtro so, a pagina 2 sai
# correta mesmo com a sessao quebrada -- a busca guardada ainda e a certa. O
# defeito so aparece quando a segunda busca precisa sobrescrever a primeira.
#
#   EXPLORE_OUT=$LADO/sessao bundle exec ruby probe_sessao.rb
#
# So leitura: filtra, pagina, ordena e volta a lista. Nao escreve nem envia
# e-mail. Registra ano e contagem, nunca nome ou e-mail (ver "Regras de
# seguranca" na SKILL.md).

require_relative "explore_common"

LISTA = "#{BASE}/course_classes"
wait = Selenium::WebDriver::Wait.new(timeout: 30)
driver = build_driver
relatorio = { lista: "/course_classes", passos: [], erros_console: [] }

# Sem `|| []`: a diferenca entre "nenhum ano no seletor" e "seletor ausente" e
# o que separa medida vazia de tela que nao montou, e as duas se leem como zero
# se forem colapsadas aqui.
def anos_da_tela(driver)
  driver.execute_script(<<~JS)
    var s = document.querySelector("#search_year");
    if (!s) return null;
    return Array.from(s.options).map(function (o) { return o.text.trim(); })
      .filter(function (t) { return /^\\d{4}$/.test(t); });
  JS
end

# O painel de busca so existe depois de clicar no link "Buscar", e clicar de
# novo com ele aberto o fecha -- daí a idempotencia.
def abrir_busca(driver, wait)
  return if driver.find_elements(css: "#search_year").any?

  driver.find_elements(link_text: "Buscar").first&.click
  wait.until { driver.find_elements(css: "#search_year").any? }
end

# `settle` sozinho nao basta na paginacao: ele confere readyState e
# jQuery.active, e no instante em que roda a requisicao do link ainda nem
# comecou -- a leitura pega a lista velha, ou vazia no meio da troca. Esperar a
# assinatura da lista MUDAR e o que amarra a medida ao fim do AJAX.
def assinatura_lista(driver)
  driver.execute_script(<<~JS)
    var linhas = document.querySelectorAll("tr td.year-column");
    var primeira = document.querySelector("tbody tr");
    return linhas.length + "|" + (primeira ? primeira.id : "");
  JS
end

# Esperar so por "a assinatura mudou" nao serve: no meio da troca a tabela fica
# VAZIA por um instante, e a assinatura vazia ja e diferente da anterior. A
# espera terminava ali e a medida saia zerada -- zero que se leria como "o
# filtro nao pegou". Por isso a condicao exige lista nao vazia tambem.
def esperar_lista_mudar(driver, antes, timeout: 15)
  Selenium::WebDriver::Wait.new(timeout: timeout).until do
    atual = assinatura_lista(driver)
    atual != antes && !atual.start_with?("0|")
  end
rescue Selenium::WebDriver::Error::TimeoutError
  nil
end

def filtrar_por_ano(driver, wait, ano)
  abrir_busca(driver, wait)
  select = Selenium::WebDriver::Support::Select.new(driver.find_element(css: "#search_year"))
  select.select_by(:text, ano)
  antes = assinatura_lista(driver)
  driver.find_element(css: "input[type=submit][value='Buscar']").click
  settle(driver, wait)
  esperar_lista_mudar(driver, antes)
end

# Le a coluna Ano da lista. A medida e "todas as linhas casam com o filtro",
# nao o conteudo delas: contagem e ano nao identificam ninguem.
def anos_listados(driver)
  driver.execute_script(<<~JS) || []
    return Array.from(document.querySelectorAll("tr td.year-column"))
      .map(function (td) { return td.innerText.trim(); });
  JS
end

def paginas(driver)
  driver.execute_script(<<~JS) || []
    return Array.from(document.querySelectorAll("a.as_paginate"))
      .map(function (a) { return a.innerText.trim(); });
  JS
end

def href_pagina(driver, texto)
  driver.execute_script(<<~JS, texto)
    var alvo = arguments[0];
    var a = Array.from(document.querySelectorAll("a.as_paginate"))
      .find(function (x) { return x.innerText.trim() === alvo; });
    return a ? a.getAttribute("href") : null;
  JS
end

def clicar_e_esperar(driver, wait, elemento)
  antes = assinatura_lista(driver)
  elemento.click
  settle(driver, wait)
  esperar_lista_mudar(driver, antes)
end

# O active_scaffold anuncia na propria tela qual busca esta valendo, no
# data-search da faixa de "filtro criado". E a medida que separa "a lista veio
# vazia" de "a lista veio vazia PORQUE o servidor esta usando outro filtro" --
# sem ela, zero linhas se le como instrumento quebrado.
def filtro_ativo(driver)
  driver.execute_script(<<~JS)
    var e = document.querySelector(".active-scaffold .filtered-message[data-search]");
    if (!e) return null;
    var d = e.getAttribute("data-search");
    try { var o = JSON.parse(d); return o && o.year != null ? String(o.year) : d; }
    catch (err) { var m = /year[^0-9]{0,8}(\\d{4})/.exec(d); return m ? m[1] : d; }
  JS
end

def registros_encontrados(driver)
  driver.execute_script(<<~JS)
    var e = document.querySelector(".active-scaffold");
    if (!e) return null;
    var m = /(\\d+)\\s+Registros? Encontrados?/i.exec(e.innerText);
    return m ? parseInt(m[1], 10) : null;
  JS
end

def registrar(relatorio, passo, ano_esperado, driver)
  anos = anos_listados(driver)
  ativo = filtro_ativo(driver)
  relatorio[:passos] << {
    passo: passo,
    ano_esperado: ano_esperado,
    # O ano que o SERVIDOR diz estar filtrando. Divergir do esperado e o
    # defeito; e o que explica linhas=0 sem acusar o instrumento.
    ano_filtrado_pelo_servidor: ativo,
    filtro_correto: ativo.nil? ? nil : ativo == ano_esperado,
    registros_encontrados: registros_encontrados(driver),
    linhas: anos.size,
    # Lista vazia nao e "nao casou": e medida que nao aconteceu, e as duas se
    # confundem num booleano so.
    medida_vazia: anos.empty?,
    todas_casam: anos.empty? ? nil : anos.uniq == [ano_esperado],
    anos_distintos: anos.uniq.sort
  }
  puts format("  %-34s servidor_filtra=%-6s linhas=%-4d todas_casam=%s",
    passo, ativo.inspect, anos.size,
    anos.empty? ? "-" : (anos.uniq == [ano_esperado]))
end

begin
  login(driver, wait)
  # O papel ativo atravessa execucoes; sem isto a sonda herda o da ultima captura.
  switch_role!(driver, wait, "Administrador")

  driver.navigate.to(LISTA)
  settle(driver, wait)

  abrir_busca(driver, wait)
  anos = anos_da_tela(driver)
  abort "Sem seletor de ano em #{LISTA}: a tela nao montou o field_search." if anos.nil?
  abort "Seletor de ano vazio em #{LISTA}." if anos.empty?

  # Ano so serve se render mais de uma pagina: sem pagina 2 nao ha o que medir.
  candidatos = []
  anos.sort.reverse.each do |ano|
    filtrar_por_ano(driver, wait, ano)
    candidatos << ano if paginas(driver).include?("2")
    break if candidatos.size == 2
  end
  relatorio[:anos_usados] = candidatos

  if candidatos.size < 2
    relatorio[:medida_recusada] =
      "Menos de dois anos com mais de uma pagina (achados: #{candidatos.inspect}). " \
      "Sem troca de filtro entre dois conjuntos paginados nao ha o que medir."
    puts "MEDIDA RECUSADA: #{relatorio[:medida_recusada]}"
  else
    a, b = candidatos
    puts "anos usados: #{a} e #{b}"

    # A descoberta ja fez buscas, e a PRIMEIRA busca de uma sessao e justamente
    # a que o defeito congela. Sem sessao nova, o filtro que sobra e o da
    # descoberta e a medida deixa de ser comparavel entre as duas rodadas.
    driver.manage.delete_all_cookies
    login(driver, wait)
    driver.navigate.to(LISTA)
    settle(driver, wait)
    puts "sessao nova para a medida"

    filtrar_por_ano(driver, wait, a)
    registrar(relatorio, "filtro A, pagina 1", a, driver)
    clicar_e_esperar(driver, wait,
      driver.find_elements(css: "a.as_paginate").find { |x| x.text.strip == "2" })
    registrar(relatorio, "filtro A, pagina 2", a, driver)

    filtrar_por_ano(driver, wait, b)
    registrar(relatorio, "filtro B, pagina 1", b, driver)
    relatorio[:href_pagina2] = href_pagina(driver, "2")
    clicar_e_esperar(driver, wait,
      driver.find_elements(css: "a.as_paginate").find { |x| x.text.strip == "2" })
    # A medida central: paginar depois de TROCAR o filtro.
    registrar(relatorio, "filtro B, pagina 2 (apos troca)", b, driver)

    filtrar_por_ano(driver, wait, b)
    sort = driver.find_elements(css: "a.as_sort").first
    if sort
      clicar_e_esperar(driver, wait, sort)
      registrar(relatorio, "filtro B, apos ordenar coluna", b, driver)
    end

    driver.navigate.to(LISTA)
    settle(driver, wait)
    begin
      Selenium::WebDriver::Wait.new(timeout: 15)
        .until { !anos_listados(driver).empty? }
    rescue Selenium::WebDriver::Error::TimeoutError
      nil
    end
    registrar(relatorio, "filtro B, ao voltar a lista", b, driver)
  end

  relatorio[:erros_console] = console_severe(driver)
ensure
  driver&.quit
end

saida = File.join(OUT, "probe_sessao.json")
File.write(saida, JSON.pretty_generate(relatorio))
puts "\nrelatorio: #{saida}"
