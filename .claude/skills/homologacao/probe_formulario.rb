#!/usr/bin/env ruby
# frozen_string_literal: true

# Le o formulario de candidatura e mede o que o HTML DIZ sobre cada campo:
# se o input exige preenchimento no navegador, se ha arquivo gravado, e em que
# formato a data foi renderizada.
#
# SO LEITURA. Nao clica, nao digita, nao submete, nao habilita o formulario.
# Navega e le o DOM. Pode rodar quantas vezes quiser, em qualquer ordem, sem
# sujar o banco -- e por isso serve de "antes" e "depois" sem restaurar nada.
#
# POR QUE LEITURA BASTA: as tres correcoes que esta versao carrega sao mudancas
# no HTML renderizado, nao no caminho de gravacao. O required entra num campo e
# sai de outro, e a data muda de formato. As consequencias aparecem na
# submissao, mas a mudanca em si esta no que a pagina diz -- e o que a pagina
# diz se le sem escrever nada.
#
# DADO REAL: a replica tem dado de aluno. Este script NUNCA grava o conteudo de
# um campo; classifica o valor em vazio/iso/br/outro e reporta so a classe. O
# rotulo do campo e nome de campo do template, nao dado pessoal.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   EXPLORE_OUT=<dir> bundle exec ruby probe_formulario.rb            # descobre as candidaturas
#   EXPLORE_OUT=<dir> bundle exec ruby probe_formulario.rb 1502 1514  # ids escolhidos
#
# SAPOS_LIMITE limita quantas candidaturas varrer na descoberta (padrao 12).

require_relative "explore_common"

abort "URL sem 'staging': #{BASE}" unless BASE.include?("staging")

LIMITE = (ENV["SAPOS_LIMITE"] || "25").to_i
IDS_PEDIDOS = ARGV.grep(/\A\d+\z/).map(&:to_i)

# O que cada caso precisa encontrar para servir de exemplar na comparacao.
# Sem exemplar, a correspondente nao tem como ser demonstrada em homologacao.
CASOS = {
  local_expedicao: "campo de texto de local de expedicao (issue #605)",
  arquivo_gravado: "campo de arquivo que JA tem arquivo (issue #664)",
  data_iso: "data renderizada em ISO, o defeito da issue #625"
}.freeze

driver = build_driver
wait = Selenium::WebDriver::Wait.new(timeout: 90)

# Le todo input visivel do formulario. `formato` e uma CLASSE, nunca o valor.
def campos_da_pagina(driver)
  driver.execute_script(<<~JS)
    var form = document.querySelector('form.as_form') || document.body;
    // Campo composto (cidade/estado/pais, rua/numero) e UM campo com varios
    // inputs, e so um deles leva required por desenho. Comparar input a input
    // acusaria os outros dois como defeito. O grupo e o <li>.
    var lis = Array.prototype.slice.call(form.querySelectorAll('li.form-element'));

    // Nem toda exigencia usa o required do HTML5. Campo de radio, por exemplo,
    // registra funcao em customFormValidations e barra por la -- esta exigido,
    // por outro mecanismo. Contar so o atributo o acusaria de defeito.
    // As funcoes referenciam os elementos por id; ler a fonte delas diz quais
    // campos estao cobertos, sem precisar chama-las (chamar mutaria o estado).
    var cobertos = {};
    var registro = window.customFormValidations || {};
    for (var chave in registro) {
      (registro[chave] || []).forEach(function (fn) {
        var src = Function.prototype.toString.call(fn);
        (src.match(/#[A-Za-z0-9_-]+/g) || []).forEach(function (tok) {
          cobertos[tok.slice(1)] = true;
        });
      });
    }
    function temValidacaoPropria(li) {
      if (!li) return false;
      if (li.id && cobertos[li.id]) return true;
      var comId = li.querySelectorAll('[id]');
      for (var i = 0; i < comId.length; i++) {
        if (cobertos[comId[i].id]) return true;
      }
      return false;
    }

    var out = [];
    Array.prototype.forEach.call(
      form.querySelectorAll('input, textarea, select'), function (el) {
        var t = (el.type || el.tagName).toLowerCase();
        if (t === 'hidden' || t === 'submit' || t === 'button') return;
        var li = el.closest('li.form-element') || el.closest('li');
        var lab = li ? li.querySelector('dt label, label') : null;
        var v = el.value || '';
        var formato = v === '' ? 'vazio'
          : /^\\d{4}-\\d{2}-\\d{2}$/.test(v) ? 'iso'
          : /^\\d{1,2}\\/\\d{1,2}\\/\\d{4}$/.test(v) ? 'br'
          : 'outro';
        out.push({
          tipo: t,
          rotulo: lab ? lab.textContent.trim().slice(0, 60) : null,
          // O <li> ganha a classe "required" quando a CONFIGURACAO do template
          // pede o campo; o atributo no input e o que o NAVEGADOR exige. Sem os
          // dois nao da para separar "nao e obrigatorio" de "e obrigatorio e
          // ninguem esta exigindo" -- que e o defeito procurado.
          config_required: li ? li.classList.contains('required') : null,
          grupo: li ? lis.indexOf(li) : -1,
          validacao_propria: temValidacaoPropria(li),
          required: el.hasAttribute('required'),
          escondido: el.offsetParent === null,
          formato: formato,
          tem_arquivo: li ? !!li.querySelector('.carrierwave_controls') : false
        });
      });
    return out;
  JS
end

# Pagina sem campo pode ser candidatura sem formulario editavel, tela de erro ou
# redirect. "Ignorada" sem motivo esconde as tres sob o mesmo rotulo.
def diagnostico_pagina(driver)
  driver.execute_script(<<~JS)
    var err = document.querySelector('.errorExplanation, .error-message');
    var h = document.querySelector('h1, h2');
    var texto = (document.body.innerText || '');
    return {
      url: location.pathname + location.search,
      tem_form_as: !!document.querySelector('form.as_form'),
      titulo: h ? h.textContent.trim().slice(0, 80) : null,
      erro: err && err.offsetParent !== null ? err.innerText.trim().slice(0, 120) : null,
      // O parcial devolve esta string, sem i18n, quando override_authorized? e
      // falso -- ou seja, quando o processo esta com staff_can_edit desligado.
      // A edicao administrativa nao existe ali, e isso e desenho.
      acesso_invalido: texto.indexOf('Acesso inválido') >= 0
    };
  JS
end

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

relatorio = { base: BASE, candidaturas: {}, sem_formulario: {}, exemplares: {}, avisos: [] }

begin
  login(driver, wait)
  switch_role!(driver, wait, "Administrador")

  ids = IDS_PEDIDOS.any? ? IDS_PEDIDOS : descobre_ids(driver, wait, LIMITE)
  abort "Nenhuma candidatura encontrada na listagem." if ids.empty?
  puts "candidaturas a varrer: #{ids.inspect}"

  ids.each do |id|
    driver.navigate.to("#{BASE}/admission_applications/#{id}/edit?override=true")
    settle(driver, wait)
    campos = campos_da_pagina(driver)

    # Medida cega e pior do que medida ausente: pagina que nao montou o
    # formulario devolve lista vazia, e zero se leria como "nada exigido".
    if campos.empty?
      diag = diagnostico_pagina(driver)
      relatorio[:sem_formulario][id] = diag
      motivo = if diag["acesso_invalido"]
        "acesso invalido -- staff_can_edit desligado no processo (desenho)"
      else
        "form_as=#{diag['tem_form_as']} erro=#{diag['erro'].inspect}"
      end
      puts "  #{id}: sem campos -- #{motivo}"
      next
    end

    expedicao = campos.select { |c| c["rotulo"].to_s.match?(/expedi/i) }
    arquivos = campos.select { |c| c["tipo"] == "file" }
    com_arquivo = arquivos.select { |c| c["tem_arquivo"] }
    # O defeito procurado: o grupo e obrigatorio pela configuracao e NINGUEM
    # exige no navegador -- nem o required do HTML5 em algum de seus inputs, nem
    # validacao propria registrada. Basta um dos dois para o campo estar coberto.
    grupos = campos.reject { |c| c["grupo"] == -1 }.group_by { |c| c["grupo"] }
    descobertos = grupos.filter_map { |_g, itens|
      next unless itens.first["config_required"]
      next if itens.any? { |c| c["required"] }
      tem_arquivo = itens.any? { |c| c["tem_arquivo"] }
      # Cada motivo EXPLICA a ausencia; sem motivo, ninguem esta exigindo.
      motivo =
        if tem_arquivo
          "arquivo ja gravado -- o navegador nao pre-preenche input de arquivo, " \
          "entao required aqui travaria a submissao; a exigencia fica no servidor"
        elsif itens.any? { |c| c["validacao_propria"] }
          "validacao propria registrada no grupo -- o que ela checa NAO e " \
          "visivel por leitura; confirme com probe_escrita.rb"
        end
      { rotulo: itens.first["rotulo"],
        tipos: itens.map { |c| c["tipo"] }.uniq,
        entradas: itens.length,
        motivo: motivo }
    }
    divergentes = descobertos.select { |d| d[:motivo].nil? }
    explicados = descobertos.reject { |d| d[:motivo].nil? }

    resumo = {
      campos: campos.length,
      expedicao: expedicao.map { |c|
        { rotulo: c["rotulo"], tipo: c["tipo"],
          config_required: c["config_required"], required: c["required"] }
      },
      divergentes: divergentes,
      explicados: explicados,
      arquivos: arquivos.length,
      arquivos_com_conteudo: com_arquivo.length,
      arquivos_obrigatorios_com_conteudo: com_arquivo.count { |c| c["config_required"] },
      arquivo_gravado_required: com_arquivo.map { |c| c["required"] }.uniq,
      datas_iso: campos.filter_map { |c| c["rotulo"] if c["formato"] == "iso" },
      datas_br: campos.count { |c| c["formato"] == "br" },
      required_escondidos: campos.count { |c| c["required"] && c["escondido"] }
    }
    relatorio[:candidaturas][id] = resumo
    puts format(
      "  %-6s campos=%-3d divergentes=%-2d arq_obrig_com_conteudo=%d/%d iso=%d br=%d req_escondido=%d",
      id, resumo[:campos], resumo[:divergentes].length,
      resumo[:arquivos_obrigatorios_com_conteudo], resumo[:arquivos_com_conteudo],
      resumo[:datas_iso].length, resumo[:datas_br], resumo[:required_escondidos]
    )
    resumo[:divergentes].each do |d|
      puts format("           DIVERGENTE: %-50s %s", d[:rotulo].inspect,
                  d[:tipos].join("/"))
    end
    resumo[:explicados].each do |d|
      puts format("           explicado:  %-50s %s", d[:rotulo].inspect,
                  d[:motivo].split(" -- ").first)
    end

    # Exemplar so vale se o registro EXERCITA o caso. Campo de arquivo que nao e
    # obrigatorio nao demonstra nada sobre required em campo de arquivo.
    if expedicao.any? { |c| c["tipo"] == "text" && c["config_required"] } &&
       !relatorio[:exemplares][:local_expedicao]
      relatorio[:exemplares][:local_expedicao] = id
      shot(driver, "exemplar_local_expedicao_#{id}")
    end
    if resumo[:arquivos_obrigatorios_com_conteudo] > 0 && !relatorio[:exemplares][:arquivo_gravado]
      relatorio[:exemplares][:arquivo_gravado] = id
      shot(driver, "exemplar_arquivo_gravado_#{id}")
    end
    if resumo[:datas_iso].any? && !relatorio[:exemplares][:data_iso]
      relatorio[:exemplares][:data_iso] = id
      shot(driver, "exemplar_data_iso_#{id}")
    end
  end

  CASOS.each_key do |caso|
    next if relatorio[:exemplares][caso]
    relatorio[:avisos] << "SEM EXEMPLAR para #{caso}: #{CASOS[caso]}"
  end

  puts "\n--- exemplares ---"
  CASOS.each do |caso, desc|
    id = relatorio[:exemplares][caso]
    puts format("  %-18s %s  (%s)", caso, id ? "candidatura #{id}" : "NENHUM", desc)
  end
  unless relatorio[:avisos].empty?
    puts "\n--- avisos ---"
    relatorio[:avisos].each { |a| puts "  #{a}" }
  end

  File.write(File.join(OUT, "probe_formulario.json"), JSON.pretty_generate(relatorio))
  puts "\njson: probe_formulario.json"
  puts "so leitura -- nada foi gravado"
ensure
  driver.quit
end
