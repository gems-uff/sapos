#!/usr/bin/env ruby
# frozen_string_literal: true

# Exercita os CAMINHOS DE ESCRITA que a varredura estatica nao alcanca. Ela
# carrega rota, tira foto e le texto -- nunca clica, nunca digita, nunca salva.
# Foi por essa fresta que passaram defeitos bloqueantes do formulario de
# candidatura, todos com o mesmo sintoma: submissao recusada sem que o candidato
# entenda por que.
#
# ESTE SCRIPT E DIAGNOSTICO, NAO E PROVA DE RELEASE. Ele mede as camadas que
# recusam uma submissao; ele nao demonstra correcao nenhuma. Correcao que muda o
# HTML renderizado -- required que entra ou sai, data que muda de formato -- se
# demonstra por leitura, com probe_formulario.rb, que nao escreve e por isso
# roda antes e depois sem restaurar nada.
#
# ESTADO: o diagnostico (passo 1) ja rodou de ponta a ponta. O ciclo de escrita
# (passo 2, --confirmar) ainda nao. Rode o diagnostico primeiro e leia o
# relatorio antes de confiar no ciclo.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   EXPLORE_OUT=<dir> bundle exec ruby probe_escrita.rb             # so diagnostico
#   EXPLORE_OUT=<dir> bundle exec ruby probe_escrita.rb --confirmar # + ciclo de escrita
#
# O que ele faz, e por que nessa ordem:
#
# 1. DIAGNOSTICO (sempre, sem persistir nada) sobre uma candidatura real. Mede as
#    tres camadas que recusam a submissao, na ordem em que aparecem:
#      a) o formulario do candidato nasce DESABILITADO na edicao administrativa
#         (can_disable_submission), atras do checkbox "Habilitar formulario nesta
#         submissao". Campo desabilitado nao e enviado: a tela salva, redireciona
#         e nao persiste nada. Isso e POR DESENHO -- o passo mede so para nao
#         confundir com defeito;
#      b) campo de arquivo obrigatorio conta como vazio para o HTML5 mesmo tendo
#         arquivo gravado (navegador nao pre-preenche input de arquivo). Exige
#         candidatura COM arquivo gravado: em registro sem arquivo esta camada
#         nao existe, e o relatorio mostra zero sem que isso queira dizer nada.
#         Escolha o id com probe_formulario.rb, que lista quem tem arquivo;
#      c) validacao propria do SAPOS sobre extensao e data, que tambem barra sem
#         mensagem quando o input esta escondido.
#
#    O diagnostico nao submete, mas CLICA no checkbox de habilitar -- e o unico
#    jeito de ver o formulario no estado em que o candidato o encontra. Nada
#    disso persiste, porque nada e submetido.
#
# 2. CICLO DE ESCRITA (so com --confirmar) sobre o aluno de teste
#    ZZ-TESTE-HOMOLOG: sobe foto, salva, confere que persistiu, remove, salva,
#    confere que sumiu. Termina no estado em que comecou. E o unico caminho de
#    escrita que este script persiste, e ele so toca registro rotulado de teste.
#
# NAO ESCREVE em candidatura real. Para exercitar criacao de candidatura com
# anexo, use abrir_processo_seletivo.rb e o formulario publico -- e lembre que a
# replica costuma exigir campos que o HTML5 nao marca como invalidos, porque a
# obrigatoriedade tambem e validada no servidor, e que os campos de arquivo
# costumam aceitar apenas pdf.

require_relative "explore_common"

CONFIRMAR = ARGV.include?("--confirmar")
ALUNO_TESTE = ENV.fetch("SAPOS_ALUNO_TESTE", "2230")
CANDIDATURA = ENV.fetch("SAPOS_CANDIDATURA_DIAG", "1502")
FIXTURE = File.expand_path("../../../spec/fixtures/user.png", __dir__)

abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 90)
relatorio = {}

def erro_visivel(driver)
  # O active_scaffold deixa no DOM, oculto, um painel "Internal Error". Ler o
  # innerText sem checar visibilidade faz QUALQUER pagina parecer quebrada.
  driver.execute_script(<<~JS)
    var e = document.querySelector('.errorExplanation, .error-message');
    return e && e.offsetParent !== null && getComputedStyle(e).display !== 'none'
      ? e.innerText.trim().slice(0, 200) : null;
  JS
end

begin
  login(driver, wait)
  # O papel ativo fica gravado no usuario e atravessa execucoes; a captura do
  # Aluno costuma ser a ultima da rodada.
  switch_role!(driver, wait, "Administrador")

  # ---------- 1. diagnostico, sem persistir ----------
  driver.navigate.to("#{BASE}/admission_applications/#{CANDIDATURA}/edit?override=true")
  settle(driver, wait)

  relatorio[:candidatura] = driver.execute_script(<<~JS)
    var campos = Array.prototype.slice.call(
      document.querySelectorAll("input[name*='fields_attributes']")
    ).filter(function (e) { return e.type !== 'hidden'; });
    var toggle = document.querySelector("input[id$='-toggle']");
    return {
      campos: campos.length,
      desabilitados: campos.filter(function (e) { return e.disabled; }).length,
      toggle_marcado: toggle ? toggle.checked : null,
      arquivos_com_conteudo: document.querySelectorAll('.carrierwave_controls').length
    };
  JS

  # Pagina que nao montou o formulario devolve zero em tudo, e zero se le como
  # "nada exigido" em vez de "nao medi". Medida cega e pior do que ausente.
  if relatorio[:candidatura]["campos"].to_i.zero?
    abort "ABORTADO: a candidatura #{CANDIDATURA} nao renderizou formulario " \
          "(id inexistente, sem permissao ou tela de erro). Nada foi medido."
  end
  if relatorio[:candidatura]["arquivos_com_conteudo"].to_i.zero?
    relatorio[:aviso_arquivo] =
      "a candidatura #{CANDIDATURA} nao tem arquivo gravado: a camada (b) nao " \
      "e observavel aqui. Use probe_formulario.rb para achar um id que sirva."
  end
  shot(driver, "diag_candidatura_#{CANDIDATURA}_antes")

  cls = driver.execute_script(<<~JS)
    var f = document.querySelector('form.as_form input[type=file]');
    return f ? Array.prototype.slice.call(f.classList).filter(function (c) {
      return c.indexOf('filledform-') === 0;
    })[0] : null;
  JS
  driver.execute_script("var t = document.getElementById('#{cls}-toggle'); if (t) t.click();") if cls
  settle(driver, wait)

  relatorio[:apos_habilitar] = driver.execute_script(<<~JS)
    var form = document.querySelector('form.as_form');
    function rotulo(el) {
      var li = el.closest('li.form-element') || el.closest('li');
      var lab = li ? li.querySelector('dt label, label') : null;
      return lab ? lab.textContent.trim().slice(0, 60) : null;
    }
    function mensagens() {
      var vistas = {}, out = [];
      Array.prototype.forEach.call(form.querySelectorAll('input, select, textarea'),
        function (e) {
          var m = e.validationMessage;
          if (!m) return;
          var chave = rotulo(e) + '|' + m;
          if (vistas[chave]) return;
          vistas[chave] = true;
          out.push({ rotulo: rotulo(e), mensagem: m });
        });
      return out.slice(0, 8);
    }

    // As validacoes proprias chamam setCustomValidity/reportValidity, ou seja,
    // MUTAM o estado de validade. Ler o HTML5 depois delas misturaria dois
    // momentos no mesmo relatorio, entao a fotografia vem antes.
    var invalidos = Array.prototype.slice.call(form.querySelectorAll(':invalid'))
                         .filter(function (e) { return e.tagName !== 'FORM'; });
    var html5 = {
      form_valido: form.checkValidity(),
      invalidos: invalidos.length,
      // Um required num input ESCONDIDO e o caso mudo: o navegador recusa e nao
      // consegue focar o elemento para mostrar o balao.
      invalidos_escondidos: invalidos.filter(function (e) {
        return e.offsetParent === null;
      }).length,
      mensagens: mensagens()
    };

    // Contagem nao diz o que consertar. Guarda QUAL reprovou.
    var reprovaram = [];
    for (var k in window.customFormValidations) {
      (window.customFormValidations[k] || []).forEach(function (fn, i) {
        try {
          if (fn() === false) reprovaram.push(k + '#' + i);
        } catch (e) {
          reprovaram.push(k + '#' + i + ' (excecao: ' + e.message.slice(0, 60) + ')');
        }
      });
    }

    return {
      html5: html5,
      validacoes_proprias_reprovando: reprovaram,
      apos_validacao_propria: {
        form_valido: form.checkValidity(),
        mensagens: mensagens()
      }
    };
  JS
  shot(driver, "diag_candidatura_#{CANDIDATURA}_habilitado")

  # ---------- 2. ciclo de escrita, so no aluno de teste ----------
  if CONFIRMAR
    abrir = lambda do
      driver.navigate.to("#{BASE}/students/#{ALUNO_TESTE}/edit")
      settle(driver, wait)
    end
    estado = lambda do
      driver.execute_script(<<~JS)
        return { nome: (document.querySelector('input[name="record[name]"]') || {}).value,
                 com_foto: document.querySelectorAll('.carrierwave_controls').length > 0 };
      JS
    end
    salvar = lambda do
      b = driver.find_element(css: "form.as_form input[type=submit]")
      driver.execute_script("arguments[0].scrollIntoView({block:'center'})", b)
      b.click
      settle(driver, wait)
    end

    abrir.call
    inicial = estado.call
    unless inicial["nome"].to_s.include?("ZZ-TESTE-HOMOLOG")
      abort "ABORTADO: o registro #{ALUNO_TESTE} nao e o aluno de teste. Nada foi alterado."
    end

    driver.find_element(css: "input[type=file][name='record[photo]']").send_keys(FIXTURE)
    salvar.call
    erro_upload = erro_visivel(driver)
    shot(driver, "ciclo_foto_apos_upload")
    abrir.call
    depois_upload = estado.call

    removeu = nil
    erro_remocao = nil
    if depois_upload["com_foto"]
      driver.execute_script(<<~JS)
        var c = document.querySelector('.carrierwave_controls');
        (c.querySelector('a.remove-file-btn') || c.querySelector('a')).click();
      JS
      settle(driver, wait)
      salvar.call
      erro_remocao = erro_visivel(driver)
      shot(driver, "ciclo_foto_apos_remocao")
      abrir.call
      removeu = !estado.call["com_foto"]
    end

    relatorio[:ciclo_foto] = {
      inicial_com_foto: inicial["com_foto"],
      upload_persistiu: depois_upload["com_foto"],
      remocao_persistiu: removeu,
      erro_no_upload: erro_upload,
      erro_na_remocao: erro_remocao,
      voltou_ao_estado_inicial: removeu == true && inicial["com_foto"] == false
    }
  end

  puts JSON.pretty_generate(relatorio)
  File.write(File.join(OUT, "probe_escrita.json"), JSON.pretty_generate(relatorio))
  puts "\njson: probe_escrita.json"
  puts "diagnostico apenas (nada persistido) -- use --confirmar para o ciclo de foto" unless CONFIRMAR
ensure
  driver.quit
end
