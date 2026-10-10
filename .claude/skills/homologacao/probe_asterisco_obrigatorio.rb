# frozen_string_literal: true

# Sonda do marcador de campo obrigatorio no formulario de candidatura.
#
# O rotulo de campo obrigatorio ganha um asterisco vermelho por CSS. Ate a
# sanitizacao do campo HTML, esse CSS vinha de um bloco <style> gravado dentro
# de campos HTML do template (o mesmo em varias instalacoes); depois dela o
# bloco e podado e a regra passa a vir de custom/admissions.scss. A sonda mede
# o que o navegador de fato renderiza -- o ::after computado de cada rotulo
# obrigatorio -- e registra se ainda ha <style> no HTML servido, para separar
# "asterisco por remendo" de "asterisco pela aplicacao".
#
# Duas telas, porque o bloco antigo valia na pagina inteira onde o template
# fosse renderizado:
#   1. o formulario publico de candidatura (apply/new), sem login;
#   2. a edicao de uma candidatura pelo administrador (override=true).
#
#   EXPLORE_OUT=<dir> ROTULO=antes  bundle exec ruby probe_asterisco_obrigatorio.rb
#   EXPLORE_OUT=<dir> ROTULO=depois bundle exec ruby probe_asterisco_obrigatorio.rb
#
# Variaveis opcionais: SAPOS_PROCESSO_URL (default doutorado-2025-1; o processo
# tem de estar ABERTO, ver abrir_processo_seletivo.rb) e SAPOS_CANDIDATURA_ID
# (default 1502, a mesma de routes_extra.txt). Comparar e diferenciar os dois
# JSON; o que tem de ser igual e a lista de rotulos com asterisco e a cor.

require_relative "explore_common"

ROTULO = ENV.fetch("ROTULO", "sonda")
PROCESSO_URL = ENV.fetch("SAPOS_PROCESSO_URL", "doutorado-2025-1")
CANDIDATURA_ID = ENV.fetch("SAPOS_CANDIDATURA_ID", "1502")
abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

MEDIDA_JS = <<~JS
  var itens = Array.from(document.querySelectorAll("li.form-element"));
  var rotulos = itens.map(function (li) {
    var label = li.querySelector("dt label");
    if (!label) { return null; }
    var s = getComputedStyle(label, "::after");
    return {
      rotulo: label.textContent.trim(),
      obrigatorio: li.classList.contains("required"),
      after_content: s.content,
      after_color: s.color
    };
  }).filter(Boolean);
  var styles = Array.from(document.querySelectorAll("style")).map(function (st) {
    return st.textContent.replace(/\\s+/g, " ").trim();
  });
  return {
    rotulos: rotulos,
    style_blocks_com_required: styles.filter(function (t) { return t.indexOf(".required") >= 0; }),
    total_style_blocks: styles.length
  };
JS

def mede(driver, wait, nome)
  settle(driver, wait)
  medida = driver.execute_script(MEDIDA_JS)
  com_asterisco = medida["rotulos"].select { |r| r["after_content"] == '"*"' }
  obrigatorios = medida["rotulos"].select { |r| r["obrigatorio"] }
  shot(driver, "#{ROTULO}_#{nome}")
  {
    url: driver.current_url.sub(/token=[^&]+/, "token=REDACTED"),
    rotulos_obrigatorios: obrigatorios.map { |r| r["rotulo"] },
    rotulos_com_asterisco: com_asterisco.map { |r| r["rotulo"] },
    cores_do_asterisco: com_asterisco.map { |r| r["after_color"] }.uniq,
    obrigatorio_sem_asterisco: (obrigatorios.map { |r| r["rotulo"] } - com_asterisco.map { |r| r["rotulo"] }),
    asterisco_em_opcional: (com_asterisco.map { |r| r["rotulo"] } - obrigatorios.map { |r| r["rotulo"] }),
    style_blocks_com_required: medida["style_blocks_com_required"].size,
    total_style_blocks: medida["total_style_blocks"],
    console_severe: console_severe(driver)
  }
end

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 30)
relatorio = { rotulo: ROTULO, versao: nil, telas: {} }

begin
  # Versao no ar, pela tela de login, antes de autenticar.
  driver.navigate.to("#{BASE}/users/sign_in")
  settle(driver, wait)
  relatorio[:versao] = driver.execute_script(
    "var m = document.body.innerText.match(/Vers[aã]o [0-9][^\\n]*/); return m ? m[0] : null;"
  )
  puts "versao: #{relatorio[:versao]}"

  # 1. Formulario publico, sem login.
  driver.navigate.to("#{BASE}/admissions/#{PROCESSO_URL}/apply/new")
  settle(driver, wait)
  if driver.find_elements(css: "li.form-element").empty?
    abort "formulario publico nao abriu em #{PROCESSO_URL}. O processo esta aberto? " \
          "Rode abrir_processo_seletivo.rb abrir <id>."
  end
  relatorio[:telas][:publico] = mede(driver, wait, "publico")
  puts "publico: #{relatorio[:telas][:publico][:rotulos_com_asterisco].size} com asterisco de " \
       "#{relatorio[:telas][:publico][:rotulos_obrigatorios].size} obrigatorios; " \
       "style com .required: #{relatorio[:telas][:publico][:style_blocks_com_required]}"

  # 2. Edicao de candidatura pelo administrador.
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")
  driver.navigate.to("#{BASE}/admission_applications/#{CANDIDATURA_ID}/edit?override=true")
  settle(driver, wait)
  if driver.find_elements(css: "li.form-element").empty?
    relatorio[:telas][:admin] = { erro: "tela de edicao sem formulario; candidatura #{CANDIDATURA_ID} existe?" }
    warn relatorio[:telas][:admin][:erro]
  else
    relatorio[:telas][:admin] = mede(driver, wait, "admin")
    puts "admin: #{relatorio[:telas][:admin][:rotulos_com_asterisco].size} com asterisco de " \
         "#{relatorio[:telas][:admin][:rotulos_obrigatorios].size} obrigatorios; " \
         "style com .required: #{relatorio[:telas][:admin][:style_blocks_com_required]}"
  end
ensure
  path = File.join(OUT, "probe_asterisco_#{ROTULO}.json")
  File.write(path, JSON.pretty_generate(relatorio))
  puts "json: #{path}"
  driver.quit
end
