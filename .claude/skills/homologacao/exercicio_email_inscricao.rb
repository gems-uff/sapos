#!/usr/bin/env ruby
# frozen_string_literal: true

# Exercita, pela tela publica, os passos da inscricao que dependem de e-mail em
# processo seletivo COM sessao: pre-inscricao, entrada com o codigo recebido,
# envio do formulario, troca de e-mail confirmada por link, desistencia da
# troca e recuperacao do codigo. Cada passo e uma execucao, com navegador novo,
# porque entre um e outro o codigo ou o link tem de ser lido na caixa de
# e-mail (Gmail via MCP, ou colado pelo mantenedor).
#
# PRE-REQUISITOS, nesta ordem (ver "Exercicio de e-mail da inscricao" no
# SKILL.md): reCAPTCHA desligado na instancia de homologacao, e redirect_email
# destravada para o endereco de teste. Sem o primeiro, todo passo para no
# captcha; sem o segundo, nada e enviado e o passo seguinte nao tem o que ler.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   export EXPLORE_OUT=<pasta da rodada>/email
#   bundle exec ruby exercicio_email_inscricao.rb pre       <processo> <nome> <email>
#   bundle exec ruby exercicio_email_inscricao.rb abrir     <processo> <email> <codigo>
#   bundle exec ruby exercicio_email_inscricao.rb enviar    <processo> <email> <codigo> [novo email]
#   bundle exec ruby exercicio_email_inscricao.rb desistir  <processo> <email> <codigo>
#   bundle exec ruby exercicio_email_inscricao.rb confirmar <link recebido>
#   bundle exec ruby exercicio_email_inscricao.rb recuperar <processo> <email>
#
# <processo> e o endereco do edital (simple_url). `enviar` preenche o que
# estiver vazio com o marcador ZZ-TESTE-HOMOLOG, como o probe_submissao.rb, e
# com [novo email] troca o campo do formulario sincronizado com o e-mail.
#
# O que imprime: o caminho final com o codigo mascarado (so o identificador),
# os avisos da tela e o que o navegador barrou. Nao imprime o codigo nem o
# link. A inscricao de teste fica na replica: apague-a ao fim (ver SKILL.md).

require_relative "explore_common"

abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

PASSO = ARGV[0]
MARCA = "ZZ-TESTE-HOMOLOG"
CODIGO = /[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}/
JPEG_1PX = "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRof" \
           "Hh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAARCAABAAEDASIAAhEBAxEB" \
           "/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9" \
           "AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3" \
           "ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKj" \
           "pKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6" \
           "/9oADAMBAAIRAxEAPwD3+iiigD//2Q=="

def mascarado(texto)
  texto.to_s.gsub(CODIGO) { |codigo| "#{codigo[0, 6]}-…" }
       .gsub(%r{(email_change/)[\w-]+}, '\1<link>')
end

# O layout sempre traz o .notice, vazio quando nao ha aviso, e o alerta sai em
# #error_login: so interessa o elemento que tem texto.
def relato(driver, rotulo)
  tela = driver.execute_script(<<~JS)
    function texto(el) { return el.innerText.replace(/\\s+/g, ' ').trim(); }
    var avisos = Array.from(document.querySelectorAll(
      '.flash, #flash_notice, .notice, #error_login, .email-change-pending, #errorExplanation'
    )).map(texto).filter(function (t) { return t.length > 0; });
    var form = document.querySelector('form.as_form') || document.querySelector('form');
    var barrados = form ? Array.from(form.querySelectorAll(':invalid')).map(function (e) {
      var li = e.closest('li.form-element') || e.closest('li');
      var lab = li ? li.querySelector('dt label, label') : null;
      return (lab ? lab.textContent.trim().slice(0, 40) : e.name) + ' (' + e.validationMessage + ')';
    }).slice(0, 8) : [];
    return {
      caminho: location.pathname, avisos: avisos.slice(0, 4), barrados: barrados,
      captcha: !!document.querySelector('.g-recaptcha, iframe[src*="recaptcha"]'),
      desistencia: !!document.querySelector('.cancel-email-change')
    };
  JS
  puts "#{rotulo}: #{mascarado(tela['caminho'])}"
  tela["avisos"].each { |aviso| puts "  aviso: #{mascarado(aviso)[0, 260]}" }
  tela["barrados"].each { |campo| puts "  barrado pelo navegador: #{campo}" }
  puts "  captcha na tela: #{tela['captcha']} | botao de desistencia: #{tela['desistencia']}"
  tela
end

def abre(driver, wait, caminho)
  driver.navigate.to("#{BASE}#{caminho}")
  settle(driver, wait)
end

# Preenche e envia o formulario da pagina que contem o elemento `ancora`. O
# envio e o requestSubmit: confere a validade como o clique no botao.
def envia_formulario(driver, wait, ancora, valores)
  enviado = driver.execute_script(<<~JS, ancora, valores)
    var form = document.querySelector(arguments[0]).closest('form');
    var valores = arguments[1];
    Object.keys(valores).forEach(function (seletor) {
      var el = form.querySelector(seletor);
      el.value = valores[seletor];
      ['input', 'change', 'keyup'].forEach(function (n) {
        el.dispatchEvent(new Event(n, { bubbles: true }));
      });
    });
    window.onbeforeunload = null;
    if (!form.checkValidity()) return false;
    form.requestSubmit();
    return true;
  JS
  sleep 3
  settle(driver, wait)
  enviado
end

def entrar(driver, wait, processo, email, codigo)
  abre(driver, wait, "/admissions/#{processo}")
  envia_formulario(driver, wait, "#recover-email", "#recover-email" => email, ".token-field" => codigo)
end

# O preenchimento e o do probe_submissao.rb: por JS, disparando input e change,
# que e do que os campos compostos precisam para remontar o valor escondido.
def preenche(driver)
  driver.execute_script(<<~JS, MARCA)
    var marca = arguments[0];
    var form = document.querySelector('form.as_form') || document.querySelector('form');
    function disparar(el) {
      ['input', 'change'].forEach(function (n) { el.dispatchEvent(new Event(n, { bubbles: true })); });
    }
    Array.prototype.forEach.call(form.querySelectorAll('li.form-element'), function (li) {
      var lab = li.querySelector('dt label, label');
      var rotulo = lab ? lab.textContent.trim() : '';
      Array.prototype.forEach.call(li.querySelectorAll('input, select, textarea'), function (el) {
        var t = (el.type || el.tagName).toLowerCase();
        if (t === 'hidden' || t === 'submit' || t === 'button' || t === 'file') return;
        if (t === 'select-one') {
          var op = Array.prototype.slice.call(el.options).filter(function (o) { return o.value !== ''; })[0];
          if (op && el.value === '') { el.value = op.value; disparar(el); }
        } else if (t === 'radio') {
          if (!li.querySelector('input[type=radio]:checked')) { el.checked = true; disparar(el); }
        } else if (t === 'checkbox') {
          if (!el.checked) { el.checked = true; disparar(el); }
        } else if (el.value === '') {
          var ehData = /data|nascimento/i.test(rotulo) || (el.className || '').indexOf('datepicker') >= 0;
          var ehEmail = t === 'email' || /e-?mail/i.test(rotulo);
          el.value = ehData ? '01/01/2000' : (ehEmail ? marca.toLowerCase() + '@example.com' : marca);
          disparar(el);
        }
      });
    });
  JS
end

def anexa(driver)
  pdf = File.join(OUT, "zz_teste.pdf")
  jpg = File.join(OUT, "zz_teste.jpg")
  File.write(pdf, "%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n" \
                  "2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n" \
                  "3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\n" \
                  "trailer<</Root 1 0 R>>\n%%EOF\n")
  File.binwrite(jpg, JPEG_1PX.unpack1("m"))
  driver.find_elements(css: "input[type=file]").each do |el|
    # campo que ja tem arquivo gravado fica como esta
    next if driver.execute_script("return !!arguments[0].closest('.file-input-controls')", el)

    rotulo = driver.execute_script(<<~JS, el)
      var li = arguments[0].closest('li.form-element') || arguments[0].closest('li');
      var lab = li ? li.querySelector('dt label, label') : null;
      return lab ? lab.textContent.trim() : '';
    JS
    driver.execute_script("arguments[0].style.display='block';arguments[0].style.visibility='visible'", el)
    el.send_keys(rotulo.match?(/foto/i) ? jpg : pdf)
  rescue StandardError => e
    warn "  anexo pulado: #{e.class}"
  end
end

# O campo do formulario sincronizado com o e-mail: o primeiro campo de e-mail
# do formulario, ou o de rotulo "e-mail" quando o valor gravado o deixou como
# texto.
def troca_email(driver, novo)
  driver.execute_script(<<~JS, novo)
    var form = document.querySelector('form.as_form') || document.querySelector('form');
    var campo = form.querySelector('li.form-element input[type=email]');
    if (!campo) {
      campo = Array.from(form.querySelectorAll('li.form-element')).filter(function (li) {
        var lab = li.querySelector('dt label, label');
        return lab && /e-?mail/i.test(lab.textContent);
      }).map(function (li) { return li.querySelector('input[type=text]'); })[0];
    }
    if (!campo) return null;
    var antes = campo.value;
    campo.value = arguments[0];
    ['input', 'change'].forEach(function (n) { campo.dispatchEvent(new Event(n, { bubbles: true })); });
    return { tipo: campo.type, mudou: antes !== arguments[0] };
  JS
end

def clica(driver, wait, seletor)
  botao = driver.find_elements(css: seletor).select(&:displayed?).last
  abort "sem #{seletor} visivel em #{mascarado(driver.current_url)}" if botao.nil?
  driver.execute_script("window.onbeforeunload = null; arguments[0].scrollIntoView({block:'center'})", botao)
  botao.click
  sleep 5
  settle(driver, wait)
end

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 120)
begin
  case PASSO
  when "pre"
    processo, nome, email = ARGV[1, 3]
    abre(driver, wait, "/admissions/#{processo}")
    relato(driver, "tela do edital")
    enviou = envia_formulario(driver, wait, "#new-email", "input[name$='[name]']" => nome, "#new-email" => email)
    puts "formulario enviado: #{enviou}"
    relato(driver, "depois da pre-inscricao")
  when "abrir"
    processo, email, codigo = ARGV[1, 3]
    entrar(driver, wait, processo, email, codigo)
    relato(driver, "depois de entrar com e-mail e codigo")
  when "enviar"
    processo, email, codigo, novo = ARGV[1, 4]
    entrar(driver, wait, processo, email, codigo)
    relato(driver, "depois de entrar")
    abre(driver, wait, "/admissions/#{processo}/apply/#{codigo}/edit")
    preenche(driver)
    anexa(driver)
    puts "campo sincronizado com o e-mail: #{troca_email(driver, novo).inspect}" if novo
    relato(driver, "formulario preenchido")
    clica(driver, wait, "#submit")
    relato(driver, "depois de enviar")
    shot(driver, "exercicio_enviar_#{novo ? 'troca' : 'primeira'}")
  when "desistir"
    processo, email, codigo = ARGV[1, 3]
    entrar(driver, wait, processo, email, codigo)
    abre(driver, wait, "/admissions/#{processo}/apply/#{codigo}")
    relato(driver, "tela da inscricao")
    clica(driver, wait, ".cancel-email-change")
    relato(driver, "depois de desistir")
  when "confirmar"
    link = ARGV[1]
    abort "link fora da instancia de homologacao" unless link.start_with?(BASE)
    driver.navigate.to(link)
    settle(driver, wait)
    relato(driver, "pagina do link")
    if driver.find_elements(css: "#submit").any?
      clica(driver, wait, "#submit")
      relato(driver, "depois de confirmar")
    end
  when "recuperar"
    processo, email = ARGV[1, 2]
    abre(driver, wait, "/admissions/#{processo}")
    driver.execute_script("document.querySelector('a.link-forgot').click()")
    enviou = envia_formulario(driver, wait, "#recover-email", "#recover-email" => email)
    puts "formulario enviado: #{enviou}"
    relato(driver, "depois de pedir a recuperacao")
  else
    abort "uso: exercicio_email_inscricao.rb <pre|abrir|enviar|desistir|confirmar|recuperar> ..."
  end
ensure
  driver.quit
end
