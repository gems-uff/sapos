# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Matriz de campos (issue #742): o que cada perfil de AbilityDataset::PERFIS vê
# e consegue gravar, campo a campo, em cada scaffold.
#
# As outras matrizes param no registro: a do Ability diz se o perfil pode a
# ação sobre ele, a das rotas prova que a tela pergunta. Dentro do registro que
# o perfil pode alterar ainda há campo que não é dele -- o professor que lança
# nota não troca o dono da turma, quem edita o próprio artigo não o passa para
# outro. Nenhuma regra do Ability diz isso: cada tela o resolve à mão, com
# helper que trava o campo e validação que recusa a mudança. Aqui se mede o
# resultado, por quatro perguntas a cada scaffold, sobre cada registro rotulado
# do conjunto de dados:
#
# - ficha: que colunas a ficha mostra;
# - formulário: que colunas o formulário de edição oferece para alterar, e
#   quais mostra travadas (campo oculto, ou escondido por estilo, não conta);
# - gravação: mandado sozinho, pelo formulário e pela edição em linha, que
#   coluna muda o banco -- todas as do scaffold, ofereça-as a tela ou não;
# - subformulário: o mesmo para as colunas das linhas associadas que o
#   formulário traz (as inscrições dentro da turma, os autores do artigo).
#
# O baseline registra tudo; a intenção escrita em NUNCA_GRAVA é cobrada à
# parte, para o perfil que não é de gestão. A gestão grava todos os campos do
# que alcança, e por isso só um registro de cada scaffold lhe é medido.
module FieldMatrix
  GESTAO = [
    "administrador", "coordenacao", "secretaria", "professor e coordenador, atuando como coordenação",
  ].freeze

  # Colunas que quem não é de gestão nunca grava, por scaffold: o dono do
  # registro e o que o prende a outro. :tudo_menos inverte: só aquelas passam.
  NUNCA_GRAVA = {
    "papers" => %w[owner period],
    "grants" => %w[professor],
    "paper_professors" => %w[paper],
    "paper_students" => %w[paper],
    "class_enrollments" => { tudo_menos: %w[grade situation disapproved_by_absence obs] },
    "course_classes" => { tudo_menos: [] },
    "course_classes > class_enrollments" => { tudo_menos: %w[grade situation disapproved_by_absence obs] },
    # O membro da comissão grava o próprio parecer, que vai pelos formulários
    # de fase; da candidatura em si, nada.
    "admissions/admission_applications" => { tudo_menos: [] },
  }.freeze

  IGNORADAS_NO_RASTRO = %w[updated_at lock_version].freeze

  def matriz_de_campos(rotulos)
    celulas = Hash.new { |hash, chave| hash[chave] = {} }
    violacoes = []
    rotulos.map { |rotulo| perfil(rotulo) }.each do |p|
      user = vestir_perfil(p)
      ability = Ability.new(user)
      scaffolds_com_modelo.each do |scaffold|
        alvos_de_campo(scaffold, p.first).each do |record, nome|
          celula = medir_campos(scaffold, record, user, ability)
          celulas[[scaffold[:controller], nome]][p.first] = celula[:texto]
          next if GESTAO.include?(p.first)

          violacoes.concat(
            contra_a_intencao(scaffold[:controller], celula).map { |v| "#{p.first} | #{scaffold[:controller]} | #{nome} => #{v}" }
          )
        end
      end
    end
    [render_campos(celulas, rotulos), violacoes]
  end

  def scaffolds_com_modelo
    @scaffolds_com_modelo ||= RouteProbe.routes.map(&:controller).uniq.sort.filter_map do |controller|
      model = RouteProbe.model_for(controller)
      next if model.nil?

      klass = "#{controller.camelize}Controller".constantize
      { controller: controller, klass: klass, model: model, config: klass.active_scaffold_config }
    end
  end

  def alvos_de_campo(scaffold, rotulo)
    rotulados = @labels.select { |record, _| record.instance_of?(scaffold[:model]) && record.persisted? }
    if rotulados.empty?
      primeiro = scaffold[:model].unscoped.first
      return {} if primeiro.nil?

      rotulados = { primeiro => "(primeiro #{scaffold[:model].name})" }
    end
    GESTAO.include?(rotulo) ? rotulados.first(1).to_h : rotulados
  end

  def rota_de(controller, acao, verbo)
    @rotas_de_campo ||= {}
    @rotas_de_campo[[controller, acao, verbo]] ||= RouteProbe.routes.find do |rota|
      rota.controller == controller && rota.action == acao && rota.verb == verbo &&
        rota.journey.required_parts == [:id]
    end
  end

  # Entra de novo a cada pedido: a exceção de um pedido recusado derruba a
  # sessão do teste.
  def pedir_campo(user, verbo, caminho, params = {})
    sign_out :user
    sign_in user
    process(verbo, caminho, params: params, env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR })
    response.status
  rescue StandardError => e
    e.class.name.demodulize
  end

  def medir_campos(scaffold, record, user, ability)
    return { texto: "não lê" } unless ability.can?(:read, record)

    celula = { ficha: ficha_de(scaffold, record, user) }
    if ability.can?(:update, record)
      celula.merge!(formulario_de(scaffold, record, user))
      celula.merge!(gravacoes_de(scaffold, record, user))
      celula[:sub] = subformularios_de(scaffold, record, user, celula.delete(:linhas))
    end
    celula[:texto] = texto_da_celula(celula, ability.can?(:update, record))
    celula
  end

  def ficha_de(scaffold, record, user)
    rota = rota_de(scaffold[:controller], "show", "GET")
    return nil if rota.nil? || !scaffold[:config].actions.include?(:show)
    return nil unless pedir_campo(user, :get, route_path(rota, id: record.id)) == 200

    response.body.scan(/class="([a-z_0-9]+)-view/).flatten.uniq.sort
  end

  # Controles do formulário, pelo nome: record[coluna] é coluna do registro,
  # record[associação][chave][coluna] é coluna de uma linha do subformulário.
  # Campo oculto é encanamento (id, marca de exclusão) e não conta.
  def formulario_de(scaffold, record, user)
    rota = rota_de(scaffold[:controller], "edit", "GET")
    return {} if rota.nil? || pedir_campo(user, :get, route_path(rota, id: record.id)) != 200

    edita, travado = Set.new, Set.new
    linhas = Hash.new { |hash, associacao| hash[associacao] = { edita: Set.new, travado: Set.new, chaves: Set.new } }
    Nokogiri::HTML(response.body).css("input, select, textarea").each do |controle|
      partes = controle["name"].to_s.scan(/\[([^\]]*)\]/).flatten
      next unless controle["name"].to_s.start_with?("record[") && partes.any?
      next if controle["type"] == "hidden" || escondido_por_estilo?(controle)

      livre = controle["disabled"].nil? && controle["readonly"].nil?
      if partes.size >= 3 && scaffold[:config].columns[partes[0]]&.association&.collection?
        linha = linhas[partes[0]]
        linha[:chaves] << partes[1]
        (livre ? linha[:edita] : linha[:travado]) << partes[2]
      else
        (livre ? edita : travado) << partes[0]
      end
    end
    { edita: edita.to_a.sort, travado: (travado - edita).to_a.sort, linhas: linhas }
  end

  # O campo que a tela esconde por estilo (display: none no próprio controle ou
  # em quem o contém) não é oferecido a quem usa a tela.
  def escondido_por_estilo?(controle)
    [controle, *controle.ancestors].any? { |no| no["style"].to_s.delete(" ").include?("display:none") }
  end

  def valor_forjado(coluna_as, model, record, nome)
    associacao = coluna_as&.association
    if associacao
      # Só a associação simples a outro registro tem um valor a forjar: o id
      # de outro registro da mesma classe.
      return nil if !associacao.belongs_to? || associacao.polymorphic?

      atual = record.public_send(associacao.foreign_key)
      return associacao.klass.unscoped.where.not(associacao.klass.primary_key => atual).order(associacao.klass.primary_key).pick(associacao.klass.primary_key)
    end
    coluna = model.columns_hash[nome.to_s]
    return nil if coluna.nil?

    atual = record[nome]
    case coluna.type
    when :string, :text then "Forjado pela matriz"
    when :integer, :decimal, :float then (atual || 0) + 1
    when :boolean then atual ? "0" : "1"
    when :date then ((atual || Date.current) + 1).to_s
    when :datetime then ((atual || Time.current) + 1.day).to_s
    end
  end

  def rastro_de(record)
    record.class.unscoped.find_by(id: record.id)&.attributes&.except(*IGNORADAS_NO_RASTRO)
  end

  # Manda uma coluna de cada vez, e desfaz: o que importa é se o banco mudou.
  def tentar_gravar(record)
    mudou = nil
    ActiveRecord::Base.transaction(requires_new: true) do
      antes = rastro_de(record)
      yield
      mudou = antes != rastro_de(record)
      raise ActiveRecord::Rollback
    end
    mudou
  end

  def gravacoes_de(scaffold, record, user)
    formulario = rota_de(scaffold[:controller], "update", "PATCH")
    em_linha = rota_de(scaffold[:controller], "update_column", "POST")
    resultado = { grava: [], recusa: [], linha_grava: [], linha_recusa: [], sem_teste: [] }
    scaffold[:config].columns.map(&:name).map(&:to_s).sort.each do |nome|
      valor = valor_forjado(scaffold[:config].columns[nome], scaffold[:model], record, nome)
      if valor.nil?
        resultado[:sem_teste] << nome
        next
      end
      if formulario
        mudou = tentar_gravar(record) do
          pedir_campo(user, :patch, route_path(formulario, id: record.id), { record: { nome => valor } })
        end
        (mudou ? resultado[:grava] : resultado[:recusa]) << nome
      end
      next unless em_linha

      mudou = tentar_gravar(record) do
        pedir_campo(user, :post, route_path(em_linha, id: record.id), { column: nome, value: valor })
      end
      (mudou ? resultado[:linha_grava] : resultado[:linha_recusa]) << nome
    end
    resultado
  end

  # As linhas associadas que o formulário traz: para a primeira de cada
  # associação, cada coluna que a tela mostra é mandada sozinha, com todas as
  # linhas presentes (linha que não vai no formulário sai da associação).
  def subformularios_de(scaffold, record, user, linhas)
    formulario = rota_de(scaffold[:controller], "update", "PATCH")
    return {} if formulario.nil? || linhas.blank?

    linhas.sort.to_h do |associacao, linha|
      coluna_as = scaffold[:config].columns[associacao]
      classe = coluna_as&.association&.klass
      associados = classe && coluna_as.association.collection? ? record.public_send(associacao).to_a : []
      alvo = associados.find { |a| linha[:chaves].include?(a.id.to_s) }
      medida = { edita: linha[:edita].to_a.sort, travado: (linha[:travado] - linha[:edita]).to_a.sort, grava: [], recusa: [] }
      if alvo
        config = scaffold[:klass].active_scaffold_config_for(classe)
        (linha[:edita] | linha[:travado]).to_a.sort.each do |nome|
          valor = valor_forjado(config.columns[nome], classe, alvo, nome)
          next if valor.nil?

          presentes = associados.to_h { |a| [a.id.to_s, { id: a.id.to_s }] }
          presentes[alvo.id.to_s][nome] = valor
          mudou = tentar_gravar(alvo) do
            pedir_campo(user, :patch, route_path(formulario, id: record.id), { record: { associacao => presentes } })
          end
          (mudou ? medida[:grava] : medida[:recusa]) << nome
        end
      end
      [associacao, medida]
    end
  end

  def texto_da_celula(celula, edita)
    partes = ["ficha: #{celula[:ficha] ? celula[:ficha].join(' ') : '(não abre)'}"]
    return (partes << "não edita").join(" | ") unless edita

    partes << "formulário edita: #{lista(celula[:edita])}"
    partes << "formulário trava: #{lista(celula[:travado])}" if celula[:travado].present?
    partes << "grava: #{lista(celula[:grava])}"
    partes << "recusa: #{lista(celula[:recusa])}" if celula[:recusa].present?
    partes << "em linha grava: #{lista(celula[:linha_grava])}"
    partes << "em linha recusa: #{lista(celula[:linha_recusa])}" if celula[:linha_recusa].present?
    celula[:sub].each do |associacao, medida|
      partes << "#{associacao}[edita: #{lista(medida[:edita])}; trava: #{lista(medida[:travado])}; " \
                "grava: #{lista(medida[:grava])}; recusa: #{lista(medida[:recusa])}]"
    end
    partes << "sem teste: #{lista(celula[:sem_teste])}" if celula[:sem_teste].present?
    partes.join(" | ")
  end

  def lista(nomes)
    nomes.blank? ? "(nada)" : nomes.join(" ")
  end

  def proibidas(regra, gravadas)
    return gravadas & regra if regra.is_a?(Array)

    gravadas - regra[:tudo_menos]
  end

  def contra_a_intencao(controller, celula)
    achados = []
    if (regra = NUNCA_GRAVA[controller])
      { "pelo formulário" => celula[:grava], "pela edição em linha" => celula[:linha_grava] }.each do |via, gravadas|
        fora = proibidas(regra, gravadas || [])
        achados << "gravou #{via}: #{fora.join(' ')}" if fora.any?
      end
    end
    (celula[:sub] || {}).each do |associacao, medida|
      regra = NUNCA_GRAVA["#{controller} > #{associacao}"]
      next if regra.nil?

      fora = proibidas(regra, medida[:grava])
      achados << "gravou em #{associacao}: #{fora.join(' ')}" if fora.any?
    end
    achados
  end

  # Um bloco por scaffold e registro; os perfis de resultado idêntico ficam
  # juntos numa linha.
  def render_campos(celulas, rotulos)
    blocos = celulas.sort_by { |(controller, nome), _| [controller, nome] }.map do |(controller, nome), por_perfil|
      grupos = rotulos.select { |rotulo| por_perfil.key?(rotulo) }.group_by { |rotulo| por_perfil[rotulo] }
      linhas = grupos.map { |texto, perfis| "  #{perfis.join(', ')}: #{texto}" }
      "== #{controller} | #{nome}\n#{linhas.join("\n")}"
    end
    "#{blocos.join("\n")}\n"
  end
end

RSpec.shared_examples "matriz de campos" do |golden, rotulos|
  include GoldenMaster
  include AbilityDataset
  include RouteProbe
  include FieldMatrix

  before(:each) do
    travel_to GoldenMaster::FROZEN_AT
    build_ability_dataset
  end
  after(:each) { travel_back }

  it "não grava campo que a intenção nega, e mantém o baseline" do
    matriz, violacoes = matriz_de_campos(rotulos)

    expect(violacoes).to be_empty, "campos gravados contra a intenção:\n#{violacoes.join("\n")}"
    expect_matches_golden(golden, matriz, format: :text)
  end
end
