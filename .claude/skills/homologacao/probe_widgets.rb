# frozen_string_literal: true
# Mede ESTILO COMPUTADO dos widgets que a varredura estatica nao alcanca:
# CodeMirror, tema das listas do active_scaffold, record_select e datepicker.
# Widget que so existe depois de um clique nao esta na foto -- uma mudanca de
# tema inteira atravessa as 120 rotas sem um pixel de diferenca.
#
# Roda IDENTICA nos dois lados: a diferenca medida tem de ser da aplicacao, nao
# do instrumento. Por isso nao altere as medidas no meio de uma rodada; para
# medir algo novo, acrescente secao e recapture os dois lados.
#
# SOMENTE LEITURA: nao salva formulario, nao dispara e-mail, nao gera documento
# assinado (as rotas de documento assinado escrevem).
#
# A secao do datepicker FORCA o bind com jQuery(...).datepicker(). Isso mede o
# tema do widget, e nao mede se ele aparece sozinho para o usuario -- o campo
# bind.antes e que registra o bind automatico. Ver "Zero diferenca na estatica
# nao e evidencia sobre widget" no SKILL.md.
#
#   EXPLORE_OUT=<dir> ROTULO=antes|depois bundle exec ruby probe_widgets.rb
$stdout.sync = true
require_relative "explore_common"

ROTULO = ENV["ROTULO"] || abort("defina ROTULO=antes|depois")
driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 60)
res = {}

def cm_medidas(driver)
  driver.execute_script(<<~JS)
    const cm = document.querySelector('.CodeMirror');
    if (!cm) return {presente: false};
    const s = getComputedStyle(cm);
    const g = document.querySelector('.CodeMirror-gutters');
    const l = document.querySelector('.CodeMirror-line');
    return {presente: true, dim: cm.offsetWidth + 'x' + cm.offsetHeight,
            position: s.position, overflow: s.overflow,
            font: s.fontFamily.slice(0,24), font_size: s.fontSize,
            line_height: s.lineHeight,
            gutter: !!g,
            gutter_position: g ? getComputedStyle(g).position : null,
            gutter_w: g ? g.offsetWidth : null,
            linha_font: l ? getComputedStyle(l).fontFamily.slice(0,24) : null,
            linhas: document.querySelectorAll('.CodeMirror-line').length};
  JS
end

begin
  login(driver, wait)
  # O papel ativo fica GRAVADO no usuario e atravessa execucoes. A captura do
  # Aluno costuma ser a ultima da rodada, entao a sonda que nao troca navega
  # como aluno: nao acha lista, nem record_select, nem campo de data, e devolve
  # tudo nil com "jQuery is not defined" -- que se le como "o widget sumiu",
  # nao como "papel errado". Medido: sem esta linha a rodada inteira volta vazia.
  switch_role!(driver, wait, "Administrador")

  # ---------- 1. versoes carregadas ----------
  driver.navigate.to("#{BASE}/pendencies")
  settle(driver, wait)
  res["versoes"] = driver.execute_script(<<~JS)
    return {jq: window.jQuery ? jQuery.fn.jquery : null,
            jqui: (window.jQuery && jQuery.ui) ? jQuery.ui.version : null,
            ptbr: !!(window.jQuery && jQuery.datepicker && jQuery.datepicker.regional['pt-BR']),
            codemirror: (window.CodeMirror && CodeMirror.version) ? CodeMirror.version : typeof window.CodeMirror};
  JS
  puts "versoes: #{res['versoes'].inspect}"

  # ---------- 2. CodeMirror (o maior risco desta mudanca) ----------
  {"assertion" => "/assertions/1/edit", "query" => "/queries/1/edit"}.each do |nome, rota|
    driver.navigate.to("#{BASE}#{rota}")
    settle(driver, wait)
    sleep 3
    m = cm_medidas(driver)
    puts "codemirror #{nome}: #{m.inspect}"
    res["codemirror_#{nome}"] = m
    shot(driver, "#{ROTULO}_codemirror_#{nome}")
  end

  # ---------- 3. tema da lista do active_scaffold ----------
  driver.navigate.to("#{BASE}/scholarships")
  settle(driver, wait)
  sleep 1
  res["tema_lista"] = driver.execute_script(<<~JS)
    const th = document.querySelector('.active-scaffold th');
    const a  = document.querySelector('.active-scaffold th a');
    const rec = document.querySelector('.active-scaffold tr.record');
    const even = document.querySelector('.active-scaffold tr.even-record');
    const act = document.querySelector('.active-scaffold td.actions a');
    return {th_bg: th ? getComputedStyle(th).backgroundColor : null,
            th_a_color: a ? getComputedStyle(a).color : null,
            rec_bg: rec ? getComputedStyle(rec).backgroundColor : null,
            even_bg: even ? getComputedStyle(even).backgroundColor : null,
            acao_bg: act ? (getComputedStyle(act).backgroundImage||'').slice(0,60) : null,
            acao_dim: act ? (act.offsetWidth + 'x' + act.offsetHeight) : null};
  JS
  puts "tema lista: #{res['tema_lista'].inspect}"
  shot(driver, "#{ROTULO}_tema_lista")

  # ---------- 4. record_select (dropdown + collation MariaDB) ----------
  driver.navigate.to("#{BASE}/scholarships")
  settle(driver, wait)
  sleep 1
  driver.execute_script(<<~JS)
    const a = Array.from(document.querySelectorAll('a')).find(x => (x.innerText||'').trim().startsWith('Adicionar'));
    if (a) a.click();
  JS
  sleep 4
  settle(driver, wait)
  campo = driver.execute_script("const e=document.querySelector('input.recordselect'); return e ? e.id : null")
  if campo
    el = driver.find_element(id: campo)
    el.click
    "Sil".each_char { |c| el.send_keys(c); sleep 0.35 }  # a skill avisa: caractere a caractere
    sleep 3
    res["recordselect"] = driver.execute_script(<<~JS)
      const cand = document.querySelectorAll('.record-select-container, .record-select');
      let d = null;
      for (const c of cand) { if (c.offsetParent !== null) { d = c; break; } }
      if (!d) return {dropdown: false, achou_containers: cand.length};
      const s = getComputedStyle(d);
      const item = d.querySelector('a, li');
      const sel = d.querySelector('.selected, .even, .odd');
      return {dropdown: true, itens: d.querySelectorAll('a, li').length,
              dim: d.offsetWidth + 'x' + d.offsetHeight,
              bg: s.backgroundColor, borda: s.borderTopWidth + ' ' + s.borderTopColor,
              zindex: s.zIndex, position: s.position,
              item_color: item ? getComputedStyle(item).color : null,
              sel_bg: sel ? getComputedStyle(sel).backgroundColor : null};
    JS
    puts "recordselect: #{res['recordselect'].inspect}"
    shot(driver, "#{ROTULO}_recordselect")
  else
    res["recordselect"] = {"campo" => false}
    puts "recordselect: campo nao encontrado"
  end

  # ---------- 5. datepicker (bind a mao: o da app e abortado pelo bug da #624) --
  driver.navigate.to("#{BASE}/notifications/1/simulate")
  settle(driver, wait)
  sleep 2
  bind = driver.execute_script(<<~JS)
    const antes = document.querySelectorAll('._param_type_date.hasDatepicker').length;
    try { jQuery('._param_type_date').datepicker();
          return {ok: true, antes: antes,
                  depois: document.querySelectorAll('._param_type_date.hasDatepicker').length}; }
    catch (e) { return {ok: false, antes: antes, erro: String(e).slice(0,120)}; }
  JS
  driver.execute_script("const c=document.querySelector('._param_type_date'); if(c){c.scrollIntoView({block:'center'}); c.focus(); c.click();}")
  sleep 2
  dp = driver.execute_script(<<~JS)
    const d = document.querySelector('#ui-datepicker-div');
    if (!d) return {calendario: false};
    const s = getComputedStyle(d);
    const hdr = d.querySelector('.ui-datepicker-header');
    const icon = d.querySelector('.ui-datepicker-prev span, .ui-datepicker-prev .ui-icon');
    const dia = d.querySelector('td a');
    return {calendario: d.offsetParent !== null, dim: d.offsetWidth + 'x' + d.offsetHeight,
            bg: s.backgroundColor,
            borda: s.borderTopWidth + ' ' + s.borderTopStyle + ' ' + s.borderTopColor,
            header_bg: hdr ? getComputedStyle(hdr).backgroundColor : null,
            seta_bg: icon ? (getComputedStyle(icon).backgroundImage||'').replace(/-[a-f0-9]{20,}/,'-DIGEST').slice(0,80) : null,
            seta_dim: icon ? (icon.offsetWidth + 'x' + icon.offsetHeight) : null,
            dia_color: dia ? getComputedStyle(dia).color : null,
            dias: d.querySelectorAll('td a').length};
  JS
  valor = driver.execute_script(<<~JS)
    const links = document.querySelectorAll('#ui-datepicker-div td a');
    const alvo = Array.from(links).find(a => a.innerText.trim() === '15') || links[10];
    if (!alvo) return null;
    alvo.click();
    const c = document.querySelector('._param_type_date');
    return c ? c.value : null;
  JS
  res["datepicker"] = dp.merge("bind" => bind, "valor" => valor)
  puts "datepicker: #{res['datepicker'].inspect}"
  shot(driver, "#{ROTULO}_datepicker")
ensure
  File.write(File.join(OUT, "probe_final_#{ROTULO}.json"), JSON.pretty_generate(res))
  puts "\njson: probe_final_#{ROTULO}.json"
  driver.quit rescue nil
end
