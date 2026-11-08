#!/usr/bin/env ruby
# frozen_string_literal: true

# Salva a edicao administrativa (override) de candidaturas sem mudar valor
# nenhum, e mede o que o salvar faz: se a gravacao passa, se volta recusada, e se
# o que a tela de exibicao mostra mudou. E o caminho de gravacao inteiro --
# AdmissionApplication#assign_form, validacoes de modelo, MariaDB -- sobre
# templates e dados reais, que a suite so conhece por fixture.
#
# ESCREVE, mas sem alterar valor: grava o mesmo conteudo que ja estava la. Pode
# mudar o que o salvar deriva sozinho (campo vazio criado para campo novo do
# template, marca de preenchido), e por isso roda na passada de escrita, antes da
# captura de cada lado. Dois modos por candidatura:
#   - desligado: os toggles "Habilitar formulario" ficam como vem (desligados),
#     que e o salvar mais comum -- lancar resultado sem tocar na inscricao;
#   - principal: liga so o toggle do formulario de inscricao, sem mudar valor.
#
# DADO REAL: o estado da candidatura e lido pela tela de exibicao e guardado so
# como hash do texto, sem horario. Nada do conteudo vai para o relatorio; da
# recusa, so o cabecalho e as primeiras linhas, que nomeiam campo, nao valor.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   EXPLORE_OUT=<dir> bundle exec ruby probe_salvar_candidatura.rb 859 1509
#
# Os ids vem do probe_mensagens_validacao.rb (os que montam formulario); no
# "depois", passe os mesmos.

require_relative "explore_common"
require "digest"

abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")
IDS = ARGV.grep(/\A\d+\z/).map(&:to_i)
abort "passe os ids das candidaturas" if IDS.empty?

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 90)

def estado(driver, wait, id)
  driver.navigate.to("#{BASE}/admission_applications/#{id}")
  settle(driver, wait)
  texto = driver.execute_script(<<~JS)
    var main = document.querySelector('.active-scaffold') || document.body;
    return main.innerText || '';
  JS
  normalizado = texto.gsub(/\d{1,2}:\d{2}(:\d{2})?/, "HH:MM").gsub(/Versão \S+/, "")
  Digest::SHA256.hexdigest(normalizado)[0, 16]
end

# A recusa de gravacao vem num bloco proprio ("Nao foi possivel gravar"), nao so
# em .errorExplanation; procura pelo texto e exige visibilidade.
def recusa_visivel(driver)
  driver.execute_script(<<~JS)
    var cands = Array.prototype.slice.call(document.querySelectorAll('.errorExplanation, .error-message, div, p'));
    for (var i = 0; i < cands.length; i++) {
      var e = cands[i];
      if (e.offsetParent === null || getComputedStyle(e).display === 'none') continue;
      var t = (e.innerText || '').trim();
      if (/^(Não foi possível gravar|.*erros? impediram)/.test(t) || e.classList.contains('errorExplanation')) {
        return t.split('\\n').slice(0, 4).join(' | ').slice(0, 300);
      }
    }
    return null;
  JS
end

def salvar(driver, wait, id, ligar_principal)
  console_severe(driver)
  driver.navigate.to("#{BASE}/admission_applications/#{id}/edit?override=true")
  settle(driver, wait)
  return { resultado: "sem formulario" } if driver.find_elements(css: ".filled-form-html-id").empty?

  if ligar_principal
    driver.execute_script(<<~JS)
      var t = document.querySelector("input[type=checkbox][id$='-toggle']");
      if (t && !t.checked) { jQuery(t).prop('checked', true).trigger('change'); }
    JS
  end
  url_edicao = driver.current_url
  botao = driver.find_elements(css: "input[type=submit][value='Atualizar']").find(&:displayed?)
  return { resultado: "sem botao Atualizar" } if botao.nil?
  botao.click
  sleep 2
  settle(driver, wait)
  recusa = recusa_visivel(driver)
  resultado =
    if driver.current_url == url_edicao && recusa.nil?
      "barrado no navegador"
    elsif recusa
      "recusado"
    else
      "salvou"
    end
  { resultado: resultado, recusa: recusa, url_final: driver.current_url.sub(BASE, ""),
    console: console_severe(driver) }
end

relatorio = { base: BASE, candidaturas: {} }
begin
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")
  IDS.each do |id|
    linha = {}
    %i[desligado principal].each do |modo|
      antes = estado(driver, wait, id)
      r = salvar(driver, wait, id, modo == :principal)
      depois = estado(driver, wait, id)
      linha[modo] = r.merge(estado_mudou: antes != depois)
      puts "  #{id} #{modo}: #{r[:resultado]}#{r[:recusa] ? " (#{r[:recusa][0, 80]})" : ''}, estado mudou: #{antes != depois}"
      driver.execute_script("window.onbeforeunload = null")
    end
    relatorio[:candidaturas][id] = linha
  end
ensure
  File.write(File.join(OUT, "probe_salvar_candidatura.json"), JSON.pretty_generate(relatorio))
  puts "relatorio: #{File.join(OUT, 'probe_salvar_candidatura.json')}"
  driver&.quit
end
