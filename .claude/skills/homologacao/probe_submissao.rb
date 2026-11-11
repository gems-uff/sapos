#!/usr/bin/env ruby
# frozen_string_literal: true

# Submete o formulario publico de candidatura, que e o caminho que a varredura
# estatica e a leitura nao alcancam: aqui o formulario e preenchido, enviado, e
# a candidatura tem de nascer do outro lado.
#
# Serve a duas perguntas diferentes, e por isso tem dois modos:
#
#   sem --confirmar  FASE 1: preenche tudo MENOS um campo e tenta enviar.
#                    Mede se o navegador barra, e em QUAL campo. Nao escreve
#                    nada -- a submissao e recusada antes de sair da pagina.
#   com --confirmar  FASE 1 e depois FASE 2: completa o campo que faltava,
#                    envia de verdade e confere que a candidatura foi criada.
#                    Apaga o que criou ao terminar (--manter preserva).
#
# A fase 1 sozinha ja e um teste de regressao barato para campo obrigatorio que
# deixou de ser exigido no cliente: o defeito aparece como "nao bloqueou", ou
# como bloqueio num campo diferente do esperado.
#
# PRE-REQUISITO: processo seletivo aberto. Use abrir_processo_seletivo.rb, e nao
# esqueca de fechar depois.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   bundle exec ruby abrir_processo_seletivo.rb abrir 5
#   EXPLORE_OUT=<dir> bundle exec ruby probe_submissao.rb
#   EXPLORE_OUT=<dir> bundle exec ruby probe_submissao.rb --confirmar
#   bundle exec ruby abrir_processo_seletivo.rb fechar 5
#
# Env: SAPOS_PROCESSO_URL (padrao doutorado-2025-1) e SAPOS_CAMPO_ALVO, o rotulo
# do campo deixado em branco (padrao "local de expedi", casado no inicio do
# rotulo -- "expedi" sozinho tambem casaria "Orgao expeditor").
#
# DADO REAL: preenche com o marcador ZZ-TESTE-HOMOLOG, que e o que permite achar
# e apagar depois. Nao transcreve valor de campo nenhum para o relatorio.
#
# A limpeza tem duas metades. Pela tela ela apaga a candidatura -- mas a
# candidatura so faz belongs_to do formulario preenchido, sem dependent, e a
# tela de formularios nao tem exclusao: o formulario (com os ~50 campos) fica
# orfao na replica a cada rodada, e muda a contagem de /filled_forms entre as
# fotos. A segunda metade roda no servidor (rails runner por ssh) e apaga so o
# formulario orfao cujos campos levam o marcador. Pede SAPOS_STAGING_SSH (host
# do ssh) e SAPOS_STAGING_INSTANCE (usuario unix da instancia, que tem a
# aplicacao em ~/instance); sem eles a sonda avisa e o orfao fica.

require "open3"
require_relative "explore_common"

CONFIRMAR = ARGV.include?("--confirmar")
MANTER = ARGV.include?("--manter")
PROCESSO_URL = ENV.fetch("SAPOS_PROCESSO_URL", "doutorado-2025-1")
CAMPO_ALVO = ENV.fetch("SAPOS_CAMPO_ALVO", "local de expedi")
MARCA = "ZZ-TESTE-HOMOLOG"
RE_ALVO = /^#{CAMPO_ALVO}/i

abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

# O campo de foto aceita so jpg, e as validacoes conferem a extensao pelo nome.
# Os dois arquivos sao gerados na hora para a sonda nao depender de fixture.
JPEG_1PX = "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRof" \
           "Hh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAARCAABAAEDASIAAhEBAxEB" \
           "/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9" \
           "AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3" \
           "ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKj" \
           "pKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6" \
           "/9oADAMBAAIRAxEAPwD3+iiigD//2Q=="

def fixtures
  pdf = File.join(OUT, "zz_teste.pdf")
  jpg = File.join(OUT, "zz_teste.jpg")
  File.write(pdf, "%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n" \
                  "2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n" \
                  "3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\n" \
                  "trailer<</Root 1 0 R>>\n%%EOF\n")
  File.binwrite(jpg, JPEG_1PX.unpack1("m"))
  [pdf, jpg]
end

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 120)
pdf, jpg = fixtures
relatorio = { processo: PROCESSO_URL, campo_alvo: CAMPO_ALVO, confirmou: CONFIRMAR }

# Preenche por JS disparando input e change, que e do que os campos compostos
# precisam para remontar o valor escondido que o servidor valida.
def preenche(driver, alvo, marca)
  driver.execute_script(<<~JS, alvo, marca)
    var alvo = new RegExp('^' + arguments[0], 'i');
    var marca = arguments[1];
    var form = document.querySelector('form.as_form') || document.querySelector('form');
    var rel = { texto: 0, data: 0, select: 0, radio: 0, check: 0, pulados: [] };
    function disparar(el) {
      ['input', 'change'].forEach(function (n) {
        el.dispatchEvent(new Event(n, { bubbles: true }));
      });
    }
    Array.prototype.forEach.call(form.querySelectorAll('li.form-element'), function (li) {
      var lab = li.querySelector('dt label, label');
      var rotulo = lab ? lab.textContent.trim() : '';
      if (alvo.test(rotulo)) { rel.pulados.push(rotulo.slice(0, 40)); return; }
      Array.prototype.forEach.call(li.querySelectorAll('input, select, textarea'), function (el) {
        var t = (el.type || el.tagName).toLowerCase();
        if (t === 'hidden' || t === 'submit' || t === 'button' || t === 'file') return;
        if (t === 'select-one') {
          var op = Array.prototype.slice.call(el.options).filter(function (o) {
            return o.value !== '';
          })[0];
          if (op) { el.value = op.value; rel.select++; disparar(el); }
        } else if (t === 'radio') {
          if (!li.querySelector('input[type=radio]:checked')) {
            el.checked = true; rel.radio++; disparar(el);
          }
        } else if (t === 'checkbox') {
          if (!el.checked) { el.checked = true; rel.check++; disparar(el); }
        } else if (el.value === '') {
          var ehData = /data|nascimento/i.test(rotulo) ||
                       (el.className || '').indexOf('datepicker') >= 0;
          el.value = ehData ? '01/01/2000' : marca;
          if (ehData) { rel.data++; } else { rel.texto++; }
          disparar(el);
        }
      });
    });
    return rel;
  JS
end

def rotulo_do(driver, el)
  driver.execute_script(<<~JS, el)
    var li = arguments[0].closest('li.form-element') || arguments[0].closest('li');
    var lab = li ? li.querySelector('dt label, label') : null;
    return lab ? lab.textContent.trim() : '';
  JS
end

# Quem esta barrando, COM NOME. "bloqueou: true" sozinho nao diz por causa de
# que, e bloqueio no campo errado passaria por sucesso.
def invalidos(driver)
  driver.execute_script(<<~JS)
    // A pagina de sucesso nao tem formulario. Sem esta guarda, o proprio
    // instrumento estoura justamente quando a submissao deu certo.
    var form = document.querySelector('form.as_form') || document.querySelector('form');
    if (!form) return [];
    return Array.prototype.slice.call(form.querySelectorAll(':invalid'))
      .filter(function (e) { return e.tagName !== 'FORM'; })
      .map(function (e) {
        var li = e.closest('li.form-element') || e.closest('li');
        var lab = li ? li.querySelector('dt label, label') : null;
        return {
          rotulo: lab ? lab.textContent.trim().slice(0, 45) : null,
          tipo: (e.type || e.tagName).toLowerCase(),
          // Required em input ESCONDIDO e o caso mudo: o navegador recusa e nao
          // consegue focar o elemento para mostrar o balao.
          escondido: e.offsetParent === null,
          mensagem: e.validationMessage
        };
      }).slice(0, 10);
  JS
end

def enviar(driver, wait)
  antes = driver.current_url
  botao = driver.find_elements(css: "input[type=submit], button[type=submit]")
                .select(&:displayed?).last
  driver.execute_script("arguments[0].scrollIntoView({block:'center'})", botao)
  botao.click
  sleep 5
  begin
    settle(driver, wait)
  rescue StandardError
    nil
  end
  driver.current_url == antes
end

def apaga_criadas(driver, wait, marca)
  # ESTA SONDA RODA ANONIMA -- o formulario publico dispensa sessao. Mas a
  # limpeza usa tela ADMINISTRATIVA, e sem login ela cai no /users/sign_in:
  # nao acha link de exclusao (nao apaga nada) e nao acha linha com o marcador
  # (conta zero). O relatorio entao dizia "restantes: 0" tendo contado a tela de
  # login, e a candidatura sobrevivia -- bloqueando a rodada seguinte com
  # "Email ja existe", porque o marcador tambem e o valor do e-mail.
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")

  # A busca do active_scaffold e por campo: ?search[name]=, nao ?search=.
  driver.navigate.to("#{BASE}/admission_applications?search[name]=#{marca}")
  settle(driver, wait)
  sleep 2
  if driver.current_url.include?("sign_in")
    abort "LIMPEZA ABORTADA: a lista caiu no login. Nada foi apagado, e a " \
          "candidatura marcada continua na replica -- apague-a antes da " \
          "proxima rodada."
  end
  ids = driver.execute_script(<<~JS)
    return Array.prototype.slice.call(document.querySelectorAll('tr'))
      .filter(function (tr) { return tr.innerText.indexOf('ZZ-TESTE-HOMOLOG') >= 0; })
      .map(function (tr) { var d = tr.querySelector('a.destroy'); return d ? d.id : null; })
      .filter(Boolean);
  JS
  ids.each do |did|
    link = driver.find_elements(id: did).first
    next if link.nil?
    driver.execute_script("arguments[0].click()", link)
    # A confirmacao e um alert NATIVO, mas nao aparece instantaneamente. Esperar
    # 1s fixo e engolir NoSuchAlertError deixa o registro vivo em silencio -- e
    # a contagem seguinte ainda assim volta zero, entao a limpeza mente. Espera
    # ate ~5s e diz quando nao confirmou.
    confirmou = false
    10.times do
      sleep 0.5
      begin
        driver.switch_to.alert.accept
        confirmou = true
        break
      rescue Selenium::WebDriver::Error::NoSuchAlertError
        next
      end
    end
    puts "  AVISO: exclusao de #{did} nao confirmada (sem alert)" unless confirmou
    sleep 3
    settle(driver, wait)
  end
  # Recontar em pagina recarregada: contar na mesma pagina que acabou de apagar
  # devolve zero mesmo quando a exclusao nao pegou no servidor.
  driver.navigate.to("#{BASE}/admission_applications?search[name]=#{marca}")
  settle(driver, wait)
  sleep 2
  abort "LIMPEZA ABORTADA: a lista caiu no login na reconferencia." if driver.current_url.include?("sign_in")

  driver.execute_script(<<~JS)
    return Array.prototype.slice.call(document.querySelectorAll('tr'))
      .filter(function (tr) { return tr.innerText.indexOf('ZZ-TESTE-HOMOLOG') >= 0; }).length;
  JS
end

# So apaga formulario que (a) tem campo com o marcador e (b) nao pertence a
# nada: nem candidatura, nem carta, nem avaliacao, resultado ou ranking. Imprime
# "apagados=N restantes=M", onde restantes conta orfaos marcados que sobraram.
RUNNER_ORFAOS = <<~'RUBY'
  marca = ARGV.fetch(0)
  ids = Admissions::FilledFormField.where("value LIKE ?", "%#{marca}%")
    .distinct.pluck(:filled_form_id)
  orfao = ->(f) {
    f.admission_application.nil? && f.letter_request.nil? &&
      f.admission_phase_evaluation.nil? && f.admission_phase_result.nil? &&
      f.admission_ranking_result.nil?
  }
  alvos = Admissions::FilledForm.where(id: ids).select(&orfao)
  alvos.each(&:destroy!)
  restantes = Admissions::FilledForm.where(id: ids).count { |f| orfao.(f) }
  puts "apagados=#{alvos.size} restantes=#{restantes}"
RUBY

def apaga_formularios_orfaos(marca)
  host = ENV["SAPOS_STAGING_SSH"].to_s
  inst = ENV["SAPOS_STAGING_INSTANCE"].to_s
  if host.empty? || inst.empty?
    puts "  AVISO: SAPOS_STAGING_SSH/SAPOS_STAGING_INSTANCE ausentes -- o " \
         "formulario preenchido da candidatura apagada ficou orfao na replica"
    return { verificado: false }
  end
  abort "INSTANCIA sem 'staging': #{inst}" unless inst.include?("staging")

  # Aspas DUPLAS no bash -lc: o $f tem de expandir no shell do ssh, que e quem
  # o criou; o shell do sudo e outro usuario e nao o conhece.
  remoto = "f=$(mktemp /tmp/orfaos.XXXXXX.rb); chmod 644 $f; cat > $f; " \
           "sudo -i -u #{inst} bash -lc \"cd ~/instance && bundle exec rails runner $f #{marca}\"; " \
           "rc=$?; rm -f $f; exit $rc"
  saida, status = Open3.capture2e("ssh", host, remoto, stdin_data: RUNNER_ORFAOS)
  linha = saida.lines.grep(/^apagados=/).last.to_s.strip
  unless status.success? && linha =~ /^apagados=(\d+) restantes=(\d+)$/
    puts "  AVISO: limpeza dos formularios orfaos falhou (exit #{status.exitstatus}):"
    puts saida.lines.last(5).map { |l| "    #{l}" }
    return { verificado: false }
  end
  { verificado: true, apagados: $1.to_i, restantes: $2.to_i }
end

begin
  driver.navigate.to("#{BASE}/admissions/#{PROCESSO_URL}/apply/new")
  settle(driver, wait)
  unless driver.find_elements(css: "form.as_form, form").any?
    abort "formulario nao abriu em #{PROCESSO_URL}. O processo esta aberto? " \
          "Rode abrir_processo_seletivo.rb abrir <id>."
  end

  # ---------- fase 1: bloqueio ----------
  relatorio[:preenchimento] = preenche(driver, CAMPO_ALVO, MARCA)
  driver.find_elements(css: "input[type=file]").each do |el|
    driver.execute_script(
      "arguments[0].style.display='block';arguments[0].style.visibility='visible'", el
    )
    el.send_keys(rotulo_do(driver, el).match?(/foto/i) ? jpg : pdf)
  rescue StandardError => e
    relatorio[:anexos_pulados] = (relatorio[:anexos_pulados] || 0) + 1
    warn "  anexo pulado: #{e.class}"
  end

  # A lista de invalidos e lida ANTES do clique: e o estado sobre o qual o
  # navegador decide. Lida depois, ela ja descreve a pagina re-renderizada pelo
  # servidor, que e outra coisa.
  barrando = invalidos(driver)
  valido_antes = driver.execute_script(
    "var f = document.querySelector('form.as_form') || document.querySelector('form');" \
    "return f ? f.checkValidity() : null"
  )
  bloqueou = enviar(driver, wait)
  # Nao bloqueou tem dois desfechos, e confundi-los esconde o defeito: ou o
  # servidor aceitou, ou recusou e re-renderizou. Navegador que barra nem posta.
  recusou_no_servidor = driver.execute_script(<<~JS)
    var e = document.querySelector('#errorExplanation, .errorExplanation');
    return !!(e && e.offsetParent !== null);
  JS
  relatorio[:fase1] = {
    valido_antes_do_clique: valido_antes,
    bloqueou: bloqueou,
    recusou_no_servidor: recusou_no_servidor,
    invalidos: barrando,
    # Bloquear nao basta: bloqueio em campo diferente do esperado passaria por
    # sucesso e esconderia o defeito procurado.
    barrou_no_alvo: barrando.any? { |x| x["rotulo"].to_s.match?(RE_ALVO) }
  }
  shot(driver, "submissao_fase1")
  puts "FASE 1 -- bloqueou: #{bloqueou} | barrou no alvo: #{relatorio[:fase1][:barrou_no_alvo]}" \
       " | recusado no servidor: #{recusou_no_servidor}"
  barrando.each { |x| puts "  invalido: #{x['rotulo'].inspect} #{x['tipo']} escondido=#{x['escondido']}" }

  # ---------- fase 2: submissao de verdade ----------
  if CONFIRMAR && bloqueou
    driver.execute_script(<<~JS, CAMPO_ALVO, MARCA)
      var alvo = new RegExp('^' + arguments[0], 'i');
      Array.prototype.forEach.call(document.querySelectorAll('li.form-element'), function (li) {
        var lab = li.querySelector('dt label, label');
        if (!lab || !alvo.test(lab.textContent.trim())) return;
        var el = li.querySelector('input');
        if (!el) return;
        el.value = arguments[1];
        ['input', 'change'].forEach(function (n) {
          el.dispatchEvent(new Event(n, { bubbles: true }));
        });
      });
    JS
    ainda = enviar(driver, wait)
    resultado = driver.execute_script(<<~JS)
      var err = document.querySelector('#errorExplanation, .errorExplanation');
      // O layout sempre traz o .notice, vazio quando nao ha aviso, e o alerta
      // sai em #error_login: o primeiro elemento achado nao e o que tem texto.
      var avisos = Array.from(document.querySelectorAll('.flash, #flash_notice, .notice, #error_login'))
        .map(function (el) { return el.innerText.replace(/\\s+/g, ' ').trim(); })
        .filter(function (texto) { return texto.length > 0; });
      return {
        url: location.pathname,
        erro: err ? err.innerText.replace(/\\s+/g, ' ').trim().slice(0, 300) : null,
        aviso: avisos.length ? avisos[0].slice(0, 200) : null
      };
    JS
    # Sair do formulario NAO e ter criado. Se o servidor recusou e re-renderizou,
    # a URL tambem muda -- e o `erro` na pagina e o que separa os dois casos.
    # Confundi-los reporta "criou: true" sobre uma submissao rejeitada, e a
    # rodada conclui que o formulario publico funciona quando ele nao foi
    # exercitado ate o fim.
    postou = !ainda
    recusado = postou && !resultado["erro"].to_s.strip.empty?
    criou = postou && !recusado
    relatorio[:fase2] = {
      postou: postou, recusado_no_servidor: recusado, criou: criou,
      resultado: resultado, invalidos: invalidos(driver)
    }
    shot(driver, "submissao_fase2")
    puts "FASE 2 -- postou: #{postou} | recusado no servidor: #{recusado} | " \
         "criou: #{criou}"
    if recusado
      puts "  motivo: #{resultado['erro'].to_s.slice(0, 120)}"
      puts "  (\"Email ja existe\" = sobrou candidatura marcada de rodada anterior;" \
           " o marcador tambem e o valor do e-mail, entao ela bloqueia a proxima)"

    end

    unless MANTER
      restantes = apaga_criadas(driver, wait, MARCA)
      orfaos = apaga_formularios_orfaos(MARCA)
      relatorio[:limpeza] = { restantes_com_marcador: restantes, formularios_orfaos: orfaos }
      puts "limpeza -- restantes com o marcador: #{restantes}"
      puts "limpeza -- formularios orfaos com o marcador: " +
           (orfaos[:verificado] ? "apagados #{orfaos[:apagados]}, restantes #{orfaos[:restantes]}" : "NAO VERIFICADO")
    end
  elsif CONFIRMAR
    puts "FASE 2 pulada: a fase 1 nao bloqueou, entao o formulario ja foi enviado."
  end

  File.write(File.join(OUT, "probe_submissao.json"), JSON.pretty_generate(relatorio))
  puts "\njson: probe_submissao.json"
  puts "so a fase de bloqueio (nada foi criado) -- use --confirmar para submeter" unless CONFIRMAR
ensure
  driver.quit
end
