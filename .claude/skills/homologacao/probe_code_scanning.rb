# frozen_string_literal: true
#
# Sonda exploratoria dos tres fluxos que a varredura estatica nao alcanca:
# todos so existem depois de um clique, entao nenhuma das 125 rotas os fotografa.
#
#   1. Pre-visualizacao de configuracao de documento -- clona um formulario
#      remoto do active_scaffold e o submete dentro de um iframe, FORA do AJAX.
#      E o unico ponto do sistema com esse desenho, e por isso o unico onde o
#      rails-ujs nao poe o header X-CSRF-Token. A medida que importa e o STATUS
#      da requisicao de preview: 422 significa token ausente.
#
#   2. Botao de PDF da simulacao de declaracao -- monta um formulario a partir
#      dos parametros da consulta e o submete. A medida e o status da requisicao
#      do PDF e a integridade dos parametros que chegaram nela.
#
#   3. Widget de condicao de formulario -- monta campos escondidos por
#      concatenacao de HTML. A medida e a presenca dos campos, o atributo
#      autocomplete e, sobretudo, erro SEVERE no console: o jQuery UI define
#      $.fn.autocomplete, e passar a chave num hash de propriedades faz o jQuery
#      CHAMAR o metodo em vez de escrever o atributo, estourando com "cannot
#      call methods prior to initialization" e abortando o resto do script.
#
# ATENCAO: o fluxo 2 ESCREVE. Cada clique no botao gera o PDF de verdade, e cada
# geracao grava um documento assinado com identificador proprio -- que aparece em
# /reports e em /versions. Rodar a sonda N vezes de um lado so faz essas duas
# telas divergirem por causa dela, e nao da mudanca. Se precisar depurar a
# sonda, depure contra o lado que ja tem baseline e conte quantas vezes rodou.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   EXPLORE_OUT=~/capturas-sapos-staging/<rodada>/exploratorio \
#     bundle exec ruby .claude/skills/homologacao/probe_code_scanning.rb
#
# Sai um resultado.json por rodada; comparar antes/depois e diferenciar o JSON.
# A saida contem dado real (screenshots e numero de matricula) -- mantenha local.

require_relative "explore_common"

WAIT = Selenium::WebDriver::Wait.new(timeout: 30)
RESULT = { flows: {} }

def record(name, data)
  RESULT[:flows][name] = data
  puts "  -> #{data.reject { |k, _| k == :screenshot }.to_json}"
end

# Os dois logs sao cumulativos, e ler drena. Sem drenar no inicio de cada fluxo,
# um fluxo que sai pelo caminho de erro (e portanto nao le o console) empurra os
# proprios erros para o relatorio do fluxo seguinte -- que os reporta como se
# fossem da tela dele.
def drain_network(driver)
  driver.logs.get(:performance)
  nil
rescue StandardError
  nil
end

def drain_console(driver)
  driver.logs.get(:browser)
  nil
rescue StandardError
  nil
end

# Devolve [{url:, status:}] das respostas recebidas desde o ultimo drain.
def responses(driver)
  driver.logs.get(:performance).filter_map do |entry|
    message = JSON.parse(entry.message) rescue next
    params = message.dig("message", "params")
    next unless message.dig("message", "method") == "Network.responseReceived"
    response = params&.dig("response") or next
    { url: response["url"].to_s, status: response["status"].to_i }
  end
rescue StandardError
  []
end

def matching(driver, pattern)
  responses(driver).select { |r| r[:url] =~ pattern }
end

driver = build_driver
begin
  login(driver, WAIT)
  # Os tres fluxos sao administrativos. Sem isto a sonda herda o papel deixado
  # pela ultima captura -- e a do aluno costuma ser a ultima.
  switch_role!(driver, WAIT, "Administrador")

  # ---------------------------------------------------------------- fluxo 1
  # Abre um registro existente em modo de edicao e clica em Visualizar. Edicao
  # SEM salvar: a pre-visualizacao nao persiste nada, e a regra da passada
  # exploratoria e nao escrever.
  puts "\n[1] pre-visualizacao de configuracao de documento"
  begin
    drain_console(driver)
    driver.navigate.to("#{BASE}/report_configurations")
    settle(driver, WAIT)

    edit = driver.find_elements(css: "a.edit, a[class*='edit']").find(&:displayed?)
    if edit.nil?
      record(:preview, { erro: "nenhum link de edicao na lista" })
    else
      edit.click
      settle(driver, WAIT)
      drain_network(driver)

      link = driver.find_elements(css: "a").find do |a|
        (a.text.to_s.strip =~ /Visualizar/i) && a.displayed? rescue false
      end

      if link.nil?
        record(:preview, { erro: "botao Visualizar nao encontrado no formulario" })
      else
        # O clone carrega o token lido da meta tag; registrar se ela existe
        # separa "o servidor recusou" de "nao havia token para enviar".
        meta = driver.execute_script(
          "var m=document.querySelector('meta[name=\"csrf-token\"]');" \
          "return m ? String(m.getAttribute('content')).length : 0"
        ).to_i

        link.click
        sleep 6 # a submissao do iframe nao passa por jQuery.active
        settle(driver, WAIT)

        preview = matching(driver, %r{/report_configurations/(\d+/)?preview})
        record(:preview, {
          meta_csrf_bytes: meta,
          requisicoes: preview,
          status: preview.map { |r| r[:status] }.uniq,
          console_severe: console_severe(driver),
          screenshot: shot(driver, "01_preview")
        })
      end
    end
  rescue StandardError => e
    record(:preview, { erro: "#{e.class}: #{e.message}" })
  end

  # ---------------------------------------------------------------- fluxo 2
  # A matricula e descoberta em tempo de execucao: e dado pessoal e nao pode
  # ser fixada num arquivo versionado.
  puts "\n[2] botao de PDF da simulacao de declaracao"
  begin
    drain_console(driver)
    # Uma matricula so nao basta: a declaracao filtra por situacao, e uma
    # matricula que nao satisfaz a consulta devolve zero linhas -- indistinguivel
    # de "a tela quebrou" se a sonda desistir na primeira. Colhe algumas da
    # listagem e tenta ate uma casar.
    # As declaracoes filtram por situacao especifica -- a primeira exige banca de
    # defesa, e nenhuma matricula do topo da listagem geral defendeu. Colher de
    # onde a condicao ja e verdadeira e o que faz a consulta devolver linhas.
    matriculas = []

    driver.navigate.to("#{BASE}/thesis_defense_committee_participations")
    settle(driver, WAIT)
    ids = driver.execute_script(<<~JS)
      var links = document.querySelectorAll("a[href*='/enrollments/']");
      var saida = [];
      for (var i = 0; i < links.length && saida.length < 4; i++) {
        var m = links[i].getAttribute('href').match(/\\/enrollments\\/(\\d+)/);
        if (m && saida.indexOf(m[1]) === -1) saida.push(m[1]);
      }
      return saida;
    JS
    Array(ids).flatten.compact.each do |id|
      driver.navigate.to("#{BASE}/enrollments/#{id}")
      settle(driver, WAIT)
      mat = driver.execute_script(<<~JS).to_s.strip
        var m = document.body.innerText.match(/Matr[ií]cula[^A-Za-z0-9]{0,40}([A-Za-z0-9._\\/-]{4,20})/);
        return m ? m[1] : '';
      JS
      matriculas << mat unless mat.empty?
    end

    driver.navigate.to("#{BASE}/enrollments")
    settle(driver, WAIT)
    gerais = driver.execute_script(<<~JS)
      var celulas = document.querySelectorAll("td[class*='enrollment_number']");
      var saida = [];
      for (var i = 0; i < celulas.length && saida.length < 4; i++) {
        var t = (celulas[i].innerText || '').trim();
        if (t) saida.push(t);
      }
      return saida;
    JS
    matriculas.concat(Array(gerais).flatten.compact)
    matriculas = matriculas.reject { |m| m.to_s.strip.empty? }.uniq

    # O botao de PDF so renderiza com @messages.any?, e a consulta exige
    # data_consulta alem da matricula. Em vez de adivinhar o conjunto de
    # parametros, preenche o formulario real: os campos declaram o proprio nome
    # em data-name, e o onchange reescreve a query string do link de simular.
    #
    # E a tela precisa ser alcancada COMO O USUARIO A ALCANCA: pela acao
    # "Simular" da lista, que o active_scaffold carrega por AJAX. Navegar direto
    # para /assertions/:id/simulate monta a tela sem o link de acao do
    # active_scaffold, e o proprio botao de simular novamente estoura com
    # "Cannot read properties of undefined (reading 'reload')" -- erro da sonda,
    # nao da aplicacao.
    hoje = Time.now.strftime("%d/%m/%Y")
    encontrou = nil
    tentativas = 0

    driver.navigate.to("#{BASE}/assertions")
    settle(driver, WAIT)
    quantas = driver.find_elements(css: "a.simulate.as_action").count

    catch(:achou) do
      (0...quantas).each do |indice|
        matriculas.each do |mat|
          tentativas += 1
          # Recarrega a lista a cada tentativa: o active_scaffold troca o DOM ao
          # abrir a acao, e os elementos guardados viram referencia obsoleta.
          driver.navigate.to("#{BASE}/assertions")
          settle(driver, WAIT)
          acoes = driver.find_elements(css: "a.simulate.as_action").select(&:displayed?)
          break if acoes[indice].nil?
          acoes[indice].click
          settle(driver, WAIT)
          sleep 2

          driver.find_elements(css: "._param_field").each do |campo|
            nome = campo.attribute("data-name").to_s
            classes = campo.attribute("class").to_s
            valor =
              if classes.include?("_param_type_date") then hoje
              elsif nome =~ /matricula/i then mat
              end
            next if valor.nil? || valor.empty?

            campo.clear
            campo.send_keys(valor)
            # ESC fecha o datepicker, que de aberto intercepta o clique seguinte.
            campo.send_keys(:escape)
            # O handler e o change do jQuery, que so dispara no blur.
            campo.send_keys(:tab)
          end
          sleep 1

          # "Simular novamente" e o mesmo link de acao, agora dentro da tela.
          novamente = driver.find_elements(css: "a.simulate.as_action.again").find(&:displayed?)
          next if novamente.nil?
          novamente.click
          settle(driver, WAIT)
          sleep 3

          if driver.find_elements(id: "generate-pdf-link").any?(&:displayed?)
            encontrou = indice
            throw :achou
          end
        end
      end
    end

    if encontrou.nil?
      record(:assertion_pdf, {
        matriculas_colhidas: matriculas.size,
        declaracoes: quantas,
        combinacoes_tentadas: tentativas,
        nao_medido: "nenhuma combinacao declaracao x matricula produziu linhas, " \
                    "entao o botao de PDF nao renderizou e o clique ficou por medir"
      })
    else
      botao = driver.find_element(id: "generate-pdf-link")
      # O data-attribute so existe depois da mudanca; medir os dois lados
      # distingue "atributo ausente" de "atributo com JSON invalido".
      attr = driver.execute_script(
        "var a=document.getElementById('generate-pdf-link');" \
        "return a.getAttribute('data-query-params')"
      )
      parseavel = driver.execute_script(<<~JS)
        var a=document.getElementById('generate-pdf-link');
        var raw=a.getAttribute('data-query-params');
        if (raw === null) return 'ausente';
        try { JSON.parse(raw); return 'ok'; } catch (e) { return 'invalido: ' + e.message; }
      JS

      drain_network(driver)
      botao.click
      sleep 6
      pdf = matching(driver, %r{assertion_pdf})

      record(:assertion_pdf, {
        declaracao_indice: encontrou,
        combinacoes_tentadas: tentativas,
        data_attribute: attr.nil? ? "ausente" : "presente(#{attr.to_s.bytesize} bytes)",
        json_parseavel: parseavel,
        requisicoes: pdf.map { |r| { status: r[:status], tem_query_params: r[:url].include?("query_params") } },
        console_severe: console_severe(driver),
        screenshot: shot(driver, "02_assertion_simulate")
      })
    end
  rescue StandardError => e
    record(:assertion_pdf, { erro: "#{e.class}: #{e.message}" })
  end

  # ---------------------------------------------------------------- fluxo 3
  puts "\n[3] widget de condicao de formulario"
  begin
    drain_console(driver)
    driver.navigate.to("#{BASE}/admission_phases")
    settle(driver, WAIT)

    edit = driver.find_elements(css: "a.edit, a[class*='edit']").find(&:displayed?)
    if edit.nil?
      record(:form_condition, { erro: "nenhum link de edicao na lista de fases" })
    else
      edit.click
      settle(driver, WAIT)
      sleep 3 # o widget monta depois do carregamento do formulario

      # Em "Nenhuma" o widget monta um campo escondido so, pelo ramo simples.
      # O ramo que a mudanca mais altera -- [mode], [form_conditions][0], [id] e
      # o campo com autocomplete do jQuery UI -- so existe a partir de
      # "Condicao". Sem selecionar, a medida nao toca no codigo em questao.
      modo = driver.find_elements(css: ".form-condition-widget > .mode > select").find(&:displayed?)
      modo_selecionado = nil
      if modo
        begin
          Selenium::WebDriver::Support::Select.new(modo).select_by(:text, "Condição")
          modo_selecionado = "Condição"
          sleep 2
        rescue StandardError => e
          modo_selecionado = "falhou: #{e.class}"
        end
      end

      medida = driver.execute_script(<<~JS)
        // Contar dentro do widget, e nao por padrao de nome: um seletor por
        // nome que nao casa devolve sempre o mesmo numero e a medida fica
        // vazia -- comparavel entre as duas versoes e cega a qualquer regressao.
        var widget = document.querySelector(".form-condition-widget");
        var escondidos = widget
          ? widget.querySelectorAll("input[type=hidden]")
          : [];
        var com_autocomplete = 0, nomes_escapados = 0;
        for (var i = 0; i < escondidos.length; i++) {
          if (escondidos[i].getAttribute('autocomplete') === 'off') com_autocomplete++;
          if (/[<>"]/.test(escondidos[i].getAttribute('name') || '')) nomes_escapados++;
        }
        // O campo de nome de campo recebe autocomplete do jQuery UI. Se o
        // widget estourou antes de inicializa-lo, ele existe sem o marcador --
        // e o sintoma da colisao entre a chave `autocomplete` e $.fn.autocomplete.
        var campo = document.querySelector(".form-condition-widget .field-input");
        return {
          hidden_condition: escondidos.length,
          com_autocomplete_off: com_autocomplete,
          nomes_com_marcacao: nomes_escapados,
          // O sufixo identifica o ramo do widget sem carregar dado nenhum.
          sufixos: Array.prototype.map.call(escondidos, function (e) {
            var n = e.getAttribute('name') || '';
            var i = n.indexOf('[');
            return i === -1 ? n : n.substring(i);
          }).sort(),
          tem_form_condition: typeof create_form_condition === 'function',
          tem_campo_field: !!campo,
          autocomplete_inicializado: campo
            ? !!(window.jQuery && jQuery(campo).data('uiAutocomplete'))
            : null
        };
      JS

      record(:form_condition, medida.merge(
        modo_selecionado: modo_selecionado,
        console_severe: console_severe(driver),
        screenshot: shot(driver, "03_admission_phase_edit")
      ))
    end
  rescue StandardError => e
    record(:form_condition, { erro: "#{e.class}: #{e.message}" })
  end

  path = File.join(OUT, "resultado.json")
  File.write(path, JSON.pretty_generate(RESULT))
  puts "\nresultado: #{path}"
ensure
  driver&.quit
end
