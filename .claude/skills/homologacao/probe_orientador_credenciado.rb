# frozen_string_literal: true
# Mede a validacao Enrollment#enrollment_has_authorized_advisor pela TELA, que e
# o unico lugar onde ela executa: e validacao de servidor, disparada no save.
#
# O cenario que diferencia as versoes e estreito. Com UMA orientacao so, remover
# o orientador da o mesmo resultado dos dois lados (a versao corrigida cai no
# `return if remaining.blank?`). O que separa e: DUAS orientacoes, exatamente uma
# credenciada no nivel da matricula -- remover a credenciada. Antes da correcao
# salva (a linha marcada para remocao ainda contava como orientador); depois,
# barra com :no_advisor_with_level.
#
# A validacao inteira esta atras de CustomVariable.enable_advisor_accreditation_validation.
# Desligada, nada disto mede coisa alguma -- a sonda recusa a medida em vez de
# relatar "sem diferenca", que se leria como "nao regrediu".
#
# A validacao irma, enrollment_has_main_advisor, NAO descarta as marcadas para
# remocao, entao ela passa nos dois lados: o bloqueio que aparecer no lado novo e
# especificamente o desta correcao.
#
# Escreve SEMPRE sobre a matricula do aluno ZZ-TESTE-HOMOLOG, nunca sobre dado
# real: no lado antigo o save PERSISTE a remocao, e isso deixaria uma matricula
# real sem orientador credenciado. A fase 3 repoe o que a fase 2 tirou.
#
#   EXPLORE_OUT=$LADO/orientador ROTULO=antes bundle exec ruby probe_orientador_credenciado.rb
#   ... --confirmar   # executa o ciclo; sem isso so preenche e relata, sem salvar
#
# Os professores sao DESCOBERTOS pelo nivel da matricula, nunca fixados por nome:
# esta pasta e versionada e nao carrega dado de pessoa real.
$stdout.sync = true
require_relative "explore_common"
require "json"

CONFIRMAR = ARGV.include?("--confirmar")
ROTULO = ENV["ROTULO"] || "sem_rotulo"
MATRICULA = (ARGV.find { |a| a =~ /\A--matricula=/ } || "--matricula=3130").split("=").last

# Copiado de preparar_aluno_de_teste.rb: o record_select nao filtra com send_keys
# de uma vez -- a requisicao sai com search vazia, a lista volta inteira e clicar
# no primeiro associa o registro ERRADO, em silencio.
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

# O active_scaffold NAO usa .errorExplanation nesta tela: a recusa sai num bloco
# proprio, com o texto "Nao foi possivel gravar". Selecionar so pelas classes
# classicas devolve nil numa tela que recusou -- e nil ali se le como "salvou",
# que e o veredito oposto. Por isso a busca e pelo TEXTO, com visibilidade.
def erro_visivel(driver)
  driver.execute_script(<<~JS)
    var alvos = Array.from(document.querySelectorAll('div,p,li,span'))
      .filter(function (e) {
        if (e.offsetParent === null) return false;
        var t = (e.innerText || '').trim();
        return t.indexOf('possível gravar') >= 0 || t.indexOf('possivel gravar') >= 0;
      });
    if (alvos.length === 0) {
      var c = document.querySelector('.error-message, .errorExplanation, #errorExplanation');
      return c && c.offsetParent !== null ? c.innerText.trim().slice(0, 400) : null;
    }
    // o menor deles e o bloco da mensagem, nao a pagina inteira que a contem
    alvos.sort(function (a, b) { return a.innerText.length - b.innerText.length; });
    return alvos[0].innerText.trim().slice(0, 400);
  JS
end

def linhas_de_orientacao(driver, matricula)
  driver.execute_script(<<~JS, matricula)
    var mat = arguments[0];
    var sub = document.querySelector('#as_enrollments-' + mat + '-advisements-subform');
    if (!sub) return [];
    return Array.from(sub.querySelectorAll('tr.association-record')).map(function (tr) {
      var prof = tr.querySelector('input.professor-input');
      var main = tr.querySelector('input.main_advisor-input');
      var del  = tr.querySelector('a.destroy, a[class*=destroy], .association-record-actions a');
      return {id: tr.id,
              nova: (tr.className || '').indexOf('association-record-new') >= 0,
              professor: prof ? prof.value : null,
              principal: main ? !!main.checked : null,
              acao: del ? (del.innerText || '').trim() : null};
    });
  JS
end

# O texto que o dropdown devolve passa por clique e re-render, e um
# StaleElementReference no meio faz o helper devolver nil mesmo tendo associado.
# Quem responde se pegou e o VALOR que ficou no campo.
def professor_no_campo(driver, matricula, chave)
  driver.execute_script(
    "var e = document.getElementById('record_professor_' + arguments[0] + '_advisements_' + arguments[1]);" \
    "return e ? e.value.trim() : null;", matricula, chave
  )
end

def salvar(driver, wait)
  botao = driver.find_elements(css: "form input[type=submit], form button[type=submit]").find(&:displayed?)
  raise "sem botao de salvar visivel no formulario" if botao.nil?
  botao.click
  settle(driver, wait)
end

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 30)
relatorio = { rotulo: ROTULO, matricula: MATRICULA, confirmado: CONFIRMAR }

begin
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")

  # --- porta: sem a variavel ligada, o caminho nao executa ---
  driver.navigate.to("#{BASE}/custom_variables?per_page=200")
  settle(driver, wait)
  valor = driver.execute_script(<<~JS)
    var alvo = null;
    Array.from(document.querySelectorAll('tr.record')).forEach(function (tr) {
      var td = Array.from(tr.querySelectorAll('td')).map(function (x) { return x.innerText.trim(); });
      var i = td.indexOf('enable_advisor_accreditation_validation');
      if (i >= 0) alvo = td[i + 1];
    });
    return alvo;
  JS
  relatorio[:variavel_credenciamento] = valor
  if valor.to_s.strip.downcase != "yes"
    relatorio[:medida] = "RECUSADA: variavel #{valor.inspect} -- a validacao nao executa nesta replica"
    puts relatorio[:medida]
    raise SystemExit
  end

  # --- nivel da matricula e professores, descobertos ---
  driver.navigate.to("#{BASE}/enrollments/#{MATRICULA}")
  settle(driver, wait)
  nivel = driver.execute_script("return document.body.innerText")[/N[íi]vel[:\s]*([^\n]+)/, 1].to_s.strip
  relatorio[:nivel] = nivel

  driver.navigate.to("#{BASE}/advisement_authorizations?per_page=200")
  settle(driver, wait)
  auths = driver.execute_script(<<~JS)
    return Array.from(document.querySelectorAll('tr.record')).map(function (tr) {
      var td = Array.from(tr.querySelectorAll('td')).map(function (x) { return x.innerText.trim(); });
      return {prof: td[0], nivel: td[1]};
    });
  JS
  credenciados = auths.select { |a| a["nivel"] == nivel }.map { |a| a["prof"] }.uniq
  outros = auths.map { |a| a["prof"] }.uniq - credenciados
  relatorio[:credenciados_no_nivel] = credenciados.size
  relatorio[:nao_credenciados_disponiveis] = outros.size

  if credenciados.empty? || outros.empty?
    relatorio[:medida] = "RECUSADA: cenario nao montavel (credenciados=#{credenciados.size}, nao credenciados=#{outros.size})"
    puts relatorio[:medida]
    raise SystemExit
  end
  prof_a = credenciados.first   # credenciado no nivel -> sera o principal
  prof_b = outros.first         # NAO credenciado no nivel
  relatorio[:papel_a] = "credenciado no nivel"
  relatorio[:papel_b] = "nao credenciado no nivel"

  # --- estado inicial ---
  driver.navigate.to("#{BASE}/enrollments/#{MATRICULA}/edit")
  settle(driver, wait)
  antes = linhas_de_orientacao(driver, MATRICULA)
  relatorio[:linhas_antes] = antes.size
  relatorio[:persistidas_antes] = antes.count { |l| !l["nova"] }
  puts "nivel=#{nivel.inspect} credenciados=#{credenciados.size} outros=#{outros.size}"
  puts "linhas no subform: #{antes.size} (persistidas: #{relatorio[:persistidas_antes]})"
  antes.each { |l| puts "  #{l.inspect}" }

  unless CONFIRMAR
    relatorio[:medida] = "DIAGNOSTICO: nada preenchido, nada salvo. Rode com --confirmar."
    puts relatorio[:medida]
    raise SystemExit
  end

  fase = (ARGV.find { |a| a =~ /\A--fase=/ } || "--fase=todas").split("=").last

  # --- FASE 1: montar o cenario (A credenciado e principal, B nao credenciado) ---
  if %w[todas 1].include?(fase)
    puts "\n[fase 1] montando A (credenciado, principal) + B (nao credenciado)"
    vazia = linhas_de_orientacao(driver, MATRICULA).find { |l| l["nova"] && l["professor"].to_s.empty? }
    chave = vazia["id"].split("_").last
    escolhido_a = record_select(driver, wait, "record_professor_#{MATRICULA}_advisements_#{chave}",
                                prof_a[0, 15], preferir: prof_a)
    caixa = driver.find_element(id: "record_main_advisor_#{MATRICULA}_advisements_#{chave}")
    caixa.click unless caixa.selected?

    driver.find_element(id: "as_enrollments-#{MATRICULA}-advisements-subform-div-create-another").click
    settle(driver, wait)
    vazia2 = linhas_de_orientacao(driver, MATRICULA).select { |l| l["nova"] && l["professor"].to_s.empty? }.last
    chave2 = vazia2["id"].split("_").last
    escolhido_b = record_select(driver, wait, "record_professor_#{MATRICULA}_advisements_#{chave2}",
                                prof_b[0, 15], preferir: prof_b)

    campo_a = professor_no_campo(driver, MATRICULA, chave)
    campo_b = professor_no_campo(driver, MATRICULA, chave2)
    a_ok = !campo_a.to_s.empty? && (campo_a.include?(prof_a) || prof_a.include?(campo_a))
    b_ok = !campo_b.to_s.empty? && (campo_b.include?(prof_b) || prof_b.include?(campo_b))
    relatorio[:fase1] = { a_casou: a_ok, b_casou: b_ok,
                          a_devolvido_pelo_dropdown: !escolhido_a.to_s.empty?,
                          b_devolvido_pelo_dropdown: !escolhido_b.to_s.empty? }
    unless a_ok && b_ok
      relatorio[:fase1][:medida] = "RECUSADA: o campo do professor nao ficou com quem se pediu"
      puts relatorio[:fase1][:medida]
      raise SystemExit
    end
    salvar(driver, wait)
    relatorio[:fase1][:erro_ao_salvar] = erro_visivel(driver)
    driver.navigate.to("#{BASE}/enrollments/#{MATRICULA}/edit")
    settle(driver, wait)
    persistidas = linhas_de_orientacao(driver, MATRICULA).reject { |l| l["nova"] }
    relatorio[:fase1][:persistidas] = persistidas.size
    relatorio[:fase1][:ok] = persistidas.size == 2
    puts "  persistidas: #{persistidas.size} | erro: #{relatorio[:fase1][:erro_ao_salvar].inspect}"
    persistidas.each { |l| puts "    #{l.inspect}" }
  end

  # --- FASE 2: a MEDIDA -- remover a credenciada e salvar ---
  if %w[todas 2].include?(fase)
    puts "\n[fase 2] removendo a orientacao CREDENCIADA e salvando"
    driver.navigate.to("#{BASE}/enrollments/#{MATRICULA}/edit")
    settle(driver, wait)
    alvo = linhas_de_orientacao(driver, MATRICULA).reject { |l| l["nova"] }
                                                  .find { |l| l["professor"].to_s.include?(prof_a[0, 12]) }
    if alvo.nil?
      relatorio[:fase2] = { medida: "RECUSADA: nao achei a orientacao credenciada persistida" }
      puts relatorio[:fase2][:medida]
      raise SystemExit
    end
    removeu = driver.execute_script(<<~JS, alvo["id"])
      var tr = document.getElementById(arguments[0]);
      if (!tr) return false;
      var a = Array.from(tr.querySelectorAll('a')).find(function (x) {
        var t = (x.innerText || '').toLowerCase();
        return t.indexOf('remov') >= 0 || t.indexOf('excluir') >= 0 || t.indexOf('destru') >= 0;
      });
      if (!a) return false;
      a.click();
      return true;
    JS
    relatorio[:fase2] = { achou_acao_remover: removeu }
    unless removeu
      relatorio[:fase2][:medida] = "RECUSADA: sem link de remocao na linha"
      puts relatorio[:fase2][:medida]
      raise SystemExit
    end
    settle(driver, wait)
    salvar(driver, wait)
    erro = erro_visivel(driver)
    driver.navigate.to("#{BASE}/enrollments/#{MATRICULA}/edit")
    settle(driver, wait)
    restantes = linhas_de_orientacao(driver, MATRICULA).reject { |l| l["nova"] }
    ainda_tem_a = restantes.any? { |l| l["professor"].to_s.include?(prof_a[0, 12]) }
    relatorio[:fase2].merge!(
      erro_visivel: erro,
      bloqueou: !erro.nil?,
      credenciada_ainda_presente: ainda_tem_a,
      persistidas_depois: restantes.size,
      veredito: (ainda_tem_a ? "BARROU: a remocao nao persistiu" : "SALVOU: matricula ficou sem orientador credenciado")
    )
    puts "  #{relatorio[:fase2][:veredito]}"
    puts "  erro na tela: #{erro.inspect}"
  end

  # --- FASE 3: restaurar o cenario para o outro lado medir o mesmo ---
  if %w[todas 3].include?(fase)
    puts "\n[fase 3] restaurando"
    driver.navigate.to("#{BASE}/enrollments/#{MATRICULA}/edit")
    settle(driver, wait)
    ja_tem = linhas_de_orientacao(driver, MATRICULA).reject { |l| l["nova"] }
                                                    .any? { |l| l["professor"].to_s.include?(prof_a[0, 12]) }
    if ja_tem
      relatorio[:fase3] = { precisou: false, ok: true }
      puts "  nada a repor"
    else
      vazia = linhas_de_orientacao(driver, MATRICULA).find { |l| l["nova"] && l["professor"].to_s.empty? }
      chave = vazia["id"].split("_").last
      escolhido = record_select(driver, wait, "record_professor_#{MATRICULA}_advisements_#{chave}",
                                prof_a[0, 15], preferir: prof_a)
      caixa = driver.find_element(id: "record_main_advisor_#{MATRICULA}_advisements_#{chave}")
      caixa.click unless caixa.selected?
      salvar(driver, wait)
      driver.navigate.to("#{BASE}/enrollments/#{MATRICULA}/edit")
      settle(driver, wait)
      final = linhas_de_orientacao(driver, MATRICULA).reject { |l| l["nova"] }
      casou = !escolhido.to_s.empty? || final.any? { |l| l["professor"].to_s.include?(prof_a[0, 12]) }
      relatorio[:fase3] = { precisou: true, casou: casou,
                            persistidas: final.size, ok: final.size == 2 }
      puts "  reposto -> persistidas: #{final.size}"
    end
  end
ensure
  # Rodar uma fase por vez e o modo normal de depurar a sonda, e cada execucao
  # so preenche as chaves da fase que correu. Sobrescrever apagaria a medida da
  # fase 2 na execucao da 3 -- que e justamente a que interessa comparar.
  dir = OUT
  arquivo = File.join(dir, "probe_orientador_#{ROTULO}.json")
  anterior = File.exist?(arquivo) ? (JSON.parse(File.read(arquivo)) rescue {}) : {}
  File.write(arquivo, JSON.pretty_generate(anterior.merge(relatorio.transform_keys(&:to_s))))
  puts "\njson: probe_orientador_#{ROTULO}.json"
  driver.quit
end
