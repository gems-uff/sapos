#!/usr/bin/env ruby
# frozen_string_literal: true

# Mede a inscricao em disciplina POR DEMANDA na tela do aluno -- o caminho do
# parcial _enroll_table_on_demand_row.
#
# POR QUE EXISTE: a varredura estatica nao vota aqui. O que o parcial gera e um
# atributo `name`, que nao e texto visivel nem pixel: nenhum dos dois
# comparadores da skill o enxerga. E o modo de falha quando o `name` esta errado
# e SILENCIOSO -- o parser deforma a chave, params[:course_ids] vem nil, a
# selecao e ignorada e nenhuma excecao sobe. Foto de tela nao distingue "gravou"
# de "ignorou".
#
# PRE-REQUISITO: semestre com janela de inscricao ABERTA. Sem isso
# display_class_schedule_table_row? reprova toda linha e a tabela vem vazia --
# e a sonda devolve zero linhas, nao "sem diferenca". Use
# abrir_quadro_de_horarios.rb e passe o semestre em SEMESTRE_TESTE.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   EXPLORE_OUT=<dir> SEMESTRE_TESTE=2027-1 bundle exec ruby probe_inscricao_on_demand.rb
#   EXPLORE_OUT=<dir> SEMESTRE_TESTE=2027-1 bundle exec ruby probe_inscricao_on_demand.rb --confirmar
#
# Sem --confirmar: LEITURA. Registra os `name` gerados por linha on-demand. Ja
# serve de regressao, porque a forma do nome e exatamente o que muda entre as
# duas versoes -- e comparar os dois JSON e o teste.
#
# Com --confirmar: submete UMA linha on-demand e confere se a inscricao gravou,
# conferindo pela lista de turmas do semestre, nao pela ausencia de erro na tela
# (o active_scaffold deixa um painel "Internal Error" OCULTO no DOM). Depois
# apaga o que criou.
#
# LIMPEZA, e ela e PARCIAL de proposito. A submissao cria turma (CourseClass) e
# pedido de inscricao (EnrollmentRequest). A turma a sonda apaga -- como o
# semestre e criado pela rodada, qualquer turma nele e da rodada, o que torna a
# identificacao segura sem campo para o marcador ZZ-TESTE-HOMOLOG.
#
# O PEDIDO NAO SAI. Ele nasce com status Efetivada, e nesse estado nao ha
# caminho nenhum de UI: a lista /enrollment_requests oferece so `edit` e `show`,
# sem `destroy`, e o checkbox #delete_request da tela do aluno nao e renderizado
# para pedido efetivado. A sonda tenta e informa quantos sobraram.
#
# Consequencia para a rodada: rode esta sonda ANTES da captura do lado, ou
# recapture os conjuntos afetados depois (`html` e `aluno`, que e onde o pedido
# aparece). Sobra de um lado so vira diferenca falsa na comparacao. Apagar de
# vez e pedido ao mantenedor, por console.

require_relative "explore_common"

CONFIRMAR = ARGV.include?("--confirmar")
MATRICULA = ENV["MATRICULA_TESTE"] || "3074"
SEMESTRE = ENV["SEMESTRE_TESTE"] || abort("defina SEMESTRE_TESTE (ex: 2027-1)")
ANO, SEM = SEMESTRE.split("-")
abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

relatorio = { semestre: SEMESTRE, matricula: MATRICULA, confirmou: CONFIRMAR }

def le_linhas(driver)
  driver.execute_script(<<~JS)
    var out = [];
    document.querySelectorAll('tr[id^="on_demand_row_"]').forEach(function (tr) {
      var cb = tr.querySelector('[id^="table_row_demand_"]');
      var sel = tr.querySelector('select[id*="course_ids"]');
      var nomes = Array.prototype.slice.call(tr.querySelectorAll('[name*="course_ids"]'))
                    .map(function (e) { return e.getAttribute('name'); });
      out.push({
        row_id: tr.id,
        checkbox_id: cb ? cb.id : null,
        select_id: sel ? sel.id : null,
        opcoes_professor: sel ? sel.options.length : null,
        names: nomes
      });
    });
    return out;
  JS
end

def apaga_pedidos(driver, wait, ano)
  driver.navigate.to("#{BASE}/enrollment_requests?search[year]=#{ano}")
  settle(driver, wait); sleep 2
  ids = driver.execute_script(<<~JS)
    return Array.prototype.slice.call(document.querySelectorAll('tr.record'))
      .filter(function (tr) { return tr.innerText.indexOf('#{ano}') >= 0; })
      .map(function (tr) { var d = tr.querySelector('a.destroy'); return d ? d.id : null; })
      .filter(Boolean);
  JS
  ids.each do |did|
    link = driver.find_elements(id: did).first
    next if link.nil?
    driver.execute_script("arguments[0].click()", link)
    sleep 1
    begin
      driver.switch_to.alert.accept
    rescue Selenium::WebDriver::Error::NoSuchAlertError
      nil
    end
    sleep 3
    settle(driver, wait)
  end
  driver.navigate.to("#{BASE}/enrollment_requests?search[year]=#{ano}")
  settle(driver, wait); sleep 2
  driver.execute_script(<<~JS)
    return Array.prototype.slice.call(document.querySelectorAll('tr.record'))
      .filter(function (tr) { return tr.innerText.indexOf('#{ano}') >= 0; }).length;
  JS
end

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 30)

begin
  login(driver, wait)
  switch_role!(driver, wait, "Aluno")
  driver.navigate.to "#{BASE}/enrollment/#{MATRICULA}/enroll/#{SEMESTRE}"
  settle(driver, wait)

  linhas = le_linhas(driver)
  relatorio[:linhas] = linhas
  # A forma do nome e a medida central: e o unico efeito visivel do parcial.
  relatorio[:formas_de_name] = linhas.flat_map { |l| l["names"] }
    .map { |n| n.sub(/\[\d+\]/, "[<id>]").sub(/course_ids\[\d+\]/, "course_ids[<id>]") }
    .uniq.sort
  puts "linhas on-demand: #{linhas.size}"
  puts "formas de name .: #{relatorio[:formas_de_name].inspect}"
  shot(driver, "on_demand_linhas")

  if linhas.empty?
    puts "ZERO linhas -- janela fechada ou nenhum tipo on_demand. Medida RECUSADA."
    relatorio[:recusada] = "sem linhas on-demand"
  elsif CONFIRMAR
    alvo = linhas.first
    curso_id = alvo["select_id"].to_s[/course_ids-(\d+)-/, 1]
    relatorio[:alvo] = { row: alvo["row_id"], curso_id: curso_id }

    sel = Selenium::WebDriver::Support::Select.new(
      driver.find_element(id: alvo["select_id"])
    )
    # Primeira opcao real (a 0 e o include_blank).
    opcao = sel.options[1]
    abort "select de professor sem opcao real" if opcao.nil?
    professor = opcao.text
    sel.select_by(:index, 1)
    driver.find_element(id: alvo["checkbox_id"]).click
    sleep 1
    driver.find_element(css: "input[type=submit], button[type=submit]").click
    sleep 4
    settle(driver, wait)

    relatorio[:apos_submeter] = {
      url: driver.current_url.sub(BASE, ""),
      saiu_do_form: !driver.current_url.include?("/enroll/")
    }
    puts "apos submeter -> #{relatorio[:apos_submeter].inspect}"
    shot(driver, "on_demand_apos_submeter")

    # Confere pela LISTA de turmas do semestre, nao pela tela do formulario.
    switch_role!(driver, wait, "Administrador")
    driver.navigate.to "#{BASE}/course_classes?search[year]=#{ANO}"
    settle(driver, wait); sleep 2
    turmas = driver.execute_script(<<~JS)
      var out = [];
      document.querySelectorAll('tr.record').forEach(function (tr) {
        var t = tr.innerText.replace(/\\s+/g, ' ');
        if (t.indexOf('#{ANO}') < 0) return;
        var d = tr.querySelector('a.destroy');
        out.push({texto: t.slice(0, 90), destroy_id: d ? d.id : null});
      });
      return out;
    JS
    relatorio[:turmas_no_semestre] = turmas.map { |t| t["texto"] }
    relatorio[:criou_turma] = turmas.any?
    puts "turmas em #{ANO}: #{turmas.size}  (criou: #{turmas.any?})"

    # Limpeza: turma primeiro, pedido depois nao importa -- sao independentes.
    turmas.each do |t|
      next if t["destroy_id"].nil?
      link = driver.find_elements(id: t["destroy_id"]).first
      next if link.nil?
      driver.execute_script("arguments[0].click()", link)
      sleep 1
      begin
        driver.switch_to.alert.accept
      rescue Selenium::WebDriver::Error::NoSuchAlertError
        nil
      end
      sleep 3
      settle(driver, wait)
    end
    driver.navigate.to "#{BASE}/course_classes?search[year]=#{ANO}"
    settle(driver, wait); sleep 2
    restantes = driver.execute_script(<<~JS)
      return Array.prototype.slice.call(document.querySelectorAll('tr.record'))
        .filter(function (tr) { return tr.innerText.indexOf('#{ANO}') >= 0; }).length;
    JS

    # O pedido de inscricao tambem tem de sair: ele aparece na tela do aluno
    # (/enrollment/<id>) e faria a captura do lado seguinte divergir por conta
    # da sonda, nao da mudanca.
    pedidos_restantes = apaga_pedidos(driver, wait, ANO)

    relatorio[:limpeza] = {
      turmas_restantes: restantes, pedidos_restantes: pedidos_restantes
    }
    puts "limpeza -- turmas restantes em #{ANO}: #{restantes}"
    puts "limpeza -- pedidos restantes em #{ANO}: #{pedidos_restantes}"
    if restantes.to_i.positive? || pedidos_restantes.to_i.positive?
      puts "ATENCAO: sobrou registro no semestre de teste; apague antes de seguir"
    end
  else
    puts "leitura apenas (nada submetido) -- use --confirmar para o ciclo completo"
  end
ensure
  File.write(File.join(OUT, "probe_inscricao_on_demand.json"),
             JSON.pretty_generate(relatorio))
  puts "json: probe_inscricao_on_demand.json"
  driver.quit
end
