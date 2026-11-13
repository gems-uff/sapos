# frozen_string_literal: true
# Exercita, tela a tela, cada campo record_select e cada campo de data que um
# formulario do active_scaffold oferece -- o que a varredura estatica nao alcanca
# e o probe_widgets.rb mede so por amostra, forcando o bind.
#
# Percorre as rotas de routes_html.txt e, em cada uma, tres containers:
#
#   - new  : GET <rota>/new, pagina inteira. O record_select se inicializa pelo
#            jQuery(document).ready do record_select.js (atributo data-rs-type).
#   - add  : lista -> link "Adicionar" (AJAX). O campo vem com script inline.
#   - busca: lista -> link "Buscar" (AJAX), campos de busca.
#
# Sao dois caminhos de inicializacao diferentes; um upgrade pode quebrar um so.
#
# Por campo record_select: bind automatico (data-rs-type removido), dropdown abre
# e lista itens depois de digitar UM caractere (a busca roda no banco), clicar no
# primeiro item preenche o hidden, o botao de limpar fica habilitado e limpa.
# dropdown_itens 0 nao distingue busca vazia de busca que respondeu 500: confira
# o log do servidor no intervalo da sonda.
# Por campo de data: o calendario abre SOZINHO no clique (sem forcar bind),
# escolher o dia 15 escreve no campo, e o formato do valor (digitos -> 9).
#
# SOMENTE LEITURA: nunca submete formulario nem tecla Enter. Nao grava nome nem
# valor de registro no JSON -- so contagens, booleanos e formato. As capturas de
# tela (uma por rota com campo) mostram dado real, como as da varredura.
#
# Ids de subform mudam entre carregamentos: neutralize-os antes de diferenciar
# os dois JSON.
#
#   EXPLORE_OUT=<dir> ROTULO=antes|depois bundle exec ruby probe_campos_widgets.rb
#   ROTAS=/rota1,/rota2 restringe a varredura (para depurar a sonda).
$stdout.sync = true
require_relative "explore_common"

ROTULO = ENV["ROTULO"] || abort("defina ROTULO=antes|depois")
ROTAS = File.readlines(File.join(__dir__, "routes_html.txt"), chomp: true)
  .map(&:strip).reject { |r| r.empty? || r.start_with?("#") || r == "/" || r.include?("?") || r.start_with?("/users/") }
  .then { |rs| ENV["ROTAS"] ? ENV["ROTAS"].split(",") : rs }

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 30)
curto = Selenium::WebDriver::Wait.new(timeout: 8)
res = {}

def logado?(driver)
  !driver.current_url.split("?").first.end_with?("/users/sign_in")
end

# Marca os campos visiveis do container com data-probe e devolve a descricao.
def listar_campos(driver, container_css)
  driver.execute_script(<<~JS, container_css)
    const raiz = document.querySelector(arguments[0]);
    if (!raiz) return null;
    const vis = e => e.offsetParent !== null;
    const out = [];
    let k = 0;
    raiz.querySelectorAll('input.recordselect').forEach(e => {
      if (!vis(e)) return;
      const id = 'p' + (k++); e.setAttribute('data-probe', id);
      out.push({probe: id, tipo: 'rs', name: e.name || e.id,
                multi: !!e.closest('.record-select-list, .record-select-multiple') ||
                       !!(e.parentElement && e.parentElement.querySelector('ul.record-select-list')),
                bind_auto: !e.hasAttribute('data-rs-type')});
    });
    raiz.querySelectorAll('input.date_picker, input.datetime_picker').forEach(e => {
      if (!vis(e)) return;
      const id = 'p' + (k++); e.setAttribute('data-probe', id);
      out.push({probe: id, tipo: e.classList.contains('datetime_picker') ? 'datetime' : 'date',
                name: e.name || e.id});
    });
    return out;
  JS
end

# Clique nativo; se outro elemento interceptar (cabecalho fixo, dica), foco + clique por JS.
def clicar(driver, el)
  el.click
rescue Selenium::WebDriver::Error::ElementClickInterceptedError
  driver.execute_script("arguments[0].focus(); arguments[0].click();", el)
end

def medir_rs(driver, curto, campo)
  el = driver.find_element(css: "[data-probe='#{campo['probe']}']")
  driver.execute_script("arguments[0].scrollIntoView({block:'center'})", el)
  clicar(driver, el)
  sleep 0.6
  "a".each_char { |c| el.send_keys(c); sleep 0.4 }
  itens = 0
  begin
    curto.until do
      itens = driver.execute_script(<<~JS)
        for (const c of document.querySelectorAll('.record-select-container')) {
          if (c.offsetParent !== null) return c.querySelectorAll('li.record').length;
        }
        return 0;
      JS
      itens.positive?
    end
  rescue Selenium::WebDriver::Error::TimeoutError
  end
  r = { "dropdown_itens" => itens }
  if itens.positive?
    item = driver.find_elements(css: ".record-select-container li.record").find(&:displayed?)
    clicar(driver, item) if item
    sleep 1.2
    r.merge!(driver.execute_script(<<~JS, el))
      const el = arguments[0];
      const par = el.parentElement;
      const hid = Array.from(par.querySelectorAll('input[type=hidden]')).filter(h => h.name);
      const lista = par.querySelector('ul.record-select-list');
      const btn = par.querySelector('.clear-input-button');
      return {hidden_preenchido: hid.some(h => h.value !== ''),
              texto_preenchido: el.value !== '',
              classe_selected: el.classList.contains('selected'),
              itens_multi: lista ? lista.querySelectorAll('li').length : null,
              botao_limpar: !!btn,
              botao_habilitado: btn ? btn.classList.contains('enabled') : null};
    JS
    btn = driver.find_elements(css: "[data-probe='#{campo['probe']}'] ~ .clear-input-button").first
    if btn&.displayed?
      clicar(driver, btn)
      sleep 0.5
      r["limpou"] = driver.execute_script("return arguments[0].value === ''", el)
    end
  end
  driver.action.send_keys(:escape).perform
  driver.execute_script("arguments[0].blur(); document.body.click();", el)
  sleep 0.4
  r
rescue StandardError => e
  { "erro_sonda" => "#{e.class}: #{e.message.lines.first.to_s.strip[0, 120]}" }
end

def medir_data(driver, campo)
  el = driver.find_element(css: "[data-probe='#{campo['probe']}']")
  driver.execute_script("arguments[0].scrollIntoView({block:'center'})", el)
  clicar(driver, el)
  sleep 1
  r = driver.execute_script(<<~JS, el)
    const d = document.querySelector('#ui-datepicker-div');
    return {calendario: !!d && d.offsetParent !== null && getComputedStyle(d).display !== 'none',
            bind: arguments[0].classList.contains('hasDatepicker'),
            mes_titulo: d ? !!d.querySelector('.ui-datepicker-title') : false,
            dias: d ? d.querySelectorAll('td a, td button').length : 0};
  JS
  if r["calendario"]
    dia = driver.find_elements(css: "#ui-datepicker-div td a").find { |a| a.text.strip == "15" }
    clicar(driver, dia) if dia
    sleep 0.6
    v = driver.execute_script("return arguments[0].value", el).to_s
    r["formato_valor"] = v.gsub(/\d/, "9")
  end
  driver.action.send_keys(:escape).perform
  driver.execute_script("arguments[0].blur(); document.body.click();", el)
  sleep 0.3
  r
rescue StandardError => e
  { "erro_sonda" => "#{e.class}: #{e.message.lines.first.to_s.strip[0, 120]}" }
end

def medir_container(driver, curto, css)
  campos = listar_campos(driver, css)
  return nil if campos.nil?
  campos.map do |c|
    medida = c["tipo"] == "rs" ? medir_rs(driver, curto, c) : medir_data(driver, c)
    c.reject { |k, _| k == "probe" }.merge(medida)
  end
end

def clicar_acao(driver, texto)
  driver.execute_script(<<~JS, texto)
    const a = Array.from(document.querySelectorAll('a.action_link, a'))
      .find(x => x.offsetParent !== null && (x.innerText || '').trim().startsWith(arguments[0]));
    if (a) { a.click(); return true; }
    return false;
  JS
end

begin
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")
  console_severe(driver) # drena

  ROTAS.each do |rota|
    linha = {}
    # --- new, pagina inteira ---
    driver.navigate.to("#{BASE}#{rota}/new")
    settle(driver, wait)
    if !logado?(driver)
      linha["sessao_perdida"] = true
      login(driver, wait)
    elsif driver.current_url.split("?").first.end_with?("/new")
      m = medir_container(driver, curto, "form.as_form.create")
      linha["new"] = m if m && !m.empty?
    end
    linha["console_new"] = console_severe(driver)

    # --- lista: Adicionar e Buscar (AJAX) ---
    driver.navigate.to("#{BASE}#{rota}")
    settle(driver, wait)
    if driver.find_elements(css: ".active-scaffold").any?
      if clicar_acao(driver, "Adicionar")
        sleep 1.5
        settle(driver, wait)
        m = medir_container(driver, curto, ".active-scaffold form.create")
        linha["add"] = m if m && !m.empty?
      end
      driver.navigate.to("#{BASE}#{rota}")
      settle(driver, wait)
      if clicar_acao(driver, "Buscar")
        sleep 1.5
        settle(driver, wait)
        m = medir_container(driver, curto, ".active-scaffold form.search")
        linha["busca"] = m if m && !m.empty?
      end
    end
    linha["console_lista"] = console_severe(driver)

    campos = %w[new add busca].sum { |k| (linha[k] || []).size }
    linha.delete("console_new") if linha["console_new"].empty?
    linha.delete("console_lista") if linha["console_lista"].empty?
    res[rota] = linha unless linha.empty?
    puts "#{rota}: #{campos} campos#{linha.key?('console_new') || linha.key?('console_lista') ? ' (console)' : ''}"
    shot(driver, "#{ROTULO}#{rota.tr('/', '_')}") if campos.positive?
  end
ensure
  File.write(File.join(OUT, "campos_widgets_#{ROTULO}.json"), JSON.pretty_generate(res))
  puts "\njson: campos_widgets_#{ROTULO}.json"
  driver.quit rescue nil
end
