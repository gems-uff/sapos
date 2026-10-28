#!/usr/bin/env ruby
# frozen_string_literal: true

# Le as mensagens que as validacoes de cliente dos formularios de candidatura
# montam, sobre os templates reais da replica. A mensagem leva o nome do campo e,
# nos campos de arquivo, a lista de extensoes -- texto que quem configura o
# template escreve, e que vive dentro de um <script>.
#
# SO LEITURA. Na edicao com override, liga os toggles "Habilitar formulario" so
# no navegador, monta o estado que faz cada validacao falhar (data invalida,
# radio e checkbox desmarcados, arquivo grande e depois de extensao estranha),
# chama as validacoes registradas -- o que o submit faria -- e le a mensagem de
# cada campo. Nunca submete, entao nada grava.
#
# O que comparar entre os lados: as mensagens por campo e os erros de console ao
# carregar a pagina. Script de campo que quebra ao carregar (uma crase no nome,
# por exemplo) aparece como erro de console e como campo sem mensagem.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   EXPLORE_OUT=<dir> bundle exec ruby probe_mensagens_validacao.rb            # descobre
#   EXPLORE_OUT=<dir> bundle exec ruby probe_mensagens_validacao.rb 1502 1514  # ids do "antes"
#
# SAPOS_LIMITE limita quantas candidaturas varrer na descoberta (padrao 25).

require_relative "explore_common"

abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

LIMITE = (ENV["SAPOS_LIMITE"] || "25").to_i
IDS_PEDIDOS = ARGV.grep(/\A\d+\z/).map(&:to_i)
ARQUIVO_GRANDE = 16 * 1024 * 1024

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 90)

def descobre_ids(driver, wait, limite)
  driver.navigate.to("#{BASE}/admission_applications?search[is_filled]=Sim")
  settle(driver, wait)
  ids = driver.execute_script(<<~JS)
    var s = new Set();
    Array.prototype.forEach.call(document.querySelectorAll("a[href*='/admission_applications/']"),
      function (a) {
        var m = a.getAttribute('href').match(/\\/admission_applications\\/(\\d+)/);
        if (m) s.add(parseInt(m[1], 10));
      });
    return Array.from(s);
  JS
  ids.sort.first(limite)
end

# Liga os formularios so no navegador e poe cada campo validavel no estado que
# reprova. Os arquivos recebem o nome e o tamanho dados.
def preparar_falhas(driver, nome_arquivo, tamanho)
  driver.execute_script(<<~JS, nome_arquivo, tamanho)
    var nome = arguments[0], tamanho = arguments[1];
    Array.prototype.forEach.call(document.querySelectorAll("input[type=checkbox][id$='-toggle']"),
      function (t) { if (!t.checked) { jQuery(t).prop('checked', true).trigger('change'); } });
    Array.prototype.forEach.call(document.querySelectorAll("input.hasDatepicker"),
      function (i) { i.value = "99/99/9999"; });
    Array.prototype.forEach.call(document.querySelectorAll("li.form-element input[type=radio]"),
      function (i) { i.checked = false; });
    Array.prototype.forEach.call(document.querySelectorAll("li.form-element input[type=checkbox]:not([id$='-toggle'])"),
      function (i) { i.checked = false; });
    Array.prototype.forEach.call(document.querySelectorAll("input[type=file]"), function (i) {
      try {
        var dt = new DataTransfer();
        dt.items.add(new File([new Uint8Array(tamanho)], nome));
        i.files = dt.files;
      } catch (e) {}
    });
  JS
end

def mensagens(driver)
  driver.execute_script(<<~JS)
    Object.keys(window.customFormValidations || {}).forEach(function (k) {
      (window.customFormValidations[k] || []).forEach(function (v) {
        try { v(); } catch (e) {}
      });
    });
    var out = [];
    Array.prototype.forEach.call(document.querySelectorAll("li.form-element"), function (li) {
      var msgs = Array.prototype.map.call(li.querySelectorAll("input"),
        function (i) { return i.validationMessage; }).filter(function (m) { return m; });
      if (!msgs.length) return;
      var lab = li.querySelector("dt label");
      out.push({ rotulo: lab ? lab.textContent.trim() : null, mensagens: msgs });
    });
    return out;
  JS
end

relatorio = { base: BASE, candidaturas: {}, sem_formulario: {} }

begin
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")
  ids = IDS_PEDIDOS.any? ? IDS_PEDIDOS : descobre_ids(driver, wait, LIMITE)
  abort "Nenhuma candidatura encontrada na listagem." if ids.empty?
  puts "candidaturas a varrer: #{ids.inspect}"

  ids.each do |id|
    console_severe(driver) # drena o que ficou da pagina anterior
    driver.navigate.to("#{BASE}/admission_applications/#{id}/edit?override=true")
    settle(driver, wait)
    erros_ao_carregar = console_severe(driver)
    unless driver.find_elements(css: ".filled-form-html-id").any?
      texto = driver.execute_script("return document.body.innerText || ''")
      relatorio[:sem_formulario][id] = texto.include?("Acesso inválido") ? "acesso invalido (staff_can_edit desligado)" : "sem formulario"
      puts "  #{id}: #{relatorio[:sem_formulario][id]}"
      next
    end

    preparar_falhas(driver, "sonda.pdf", ARQUIVO_GRANDE)
    por_tamanho = mensagens(driver)
    preparar_falhas(driver, "sonda.zzz", 10)
    por_extensao = mensagens(driver)
    relatorio[:candidaturas][id] = {
      erros_de_console_ao_carregar: erros_ao_carregar,
      com_arquivo_grande: por_tamanho,
      com_extensao_estranha: por_extensao,
      rotulos_com_aspas_ou_e_comercial: (por_tamanho + por_extensao)
        .map { |m| m["rotulo"].to_s }.uniq.count { |r| r.match?(/['&`]|\$\{/) },
    }
    puts "  #{id}: #{por_tamanho.size} campo(s) com mensagem (arquivo grande), " \
         "#{por_extensao.size} (extensao), console ao carregar: #{erros_ao_carregar.size}"
    driver.execute_script("window.onbeforeunload = null; if (window.jQuery) { jQuery(window).off('beforeunload'); }")
  end
ensure
  File.write(File.join(OUT, "probe_mensagens_validacao.json"), JSON.pretty_generate(relatorio))
  puts "relatorio: #{File.join(OUT, 'probe_mensagens_validacao.json')}"
  driver&.quit
end
