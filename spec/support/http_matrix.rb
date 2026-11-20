# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Matriz de permissões pelas rotas (issue #742): cada perfil de
# AbilityDataset::PERFIS percorre todas as rotas da aplicação, e a rota que
# pede :id é visitada com cada registro rotulado do modelo do controller.
#
# A matriz do Ability (spec/models/ability_matrix_spec.rb) pergunta ao
# Ability; aqui se prova que cada tela pergunta também, e que a resposta dela
# casa com a dele. Duas regras, que valem para toda rota cujo controller tem
# modelo:
#
# - GET que o Ability nega não abre: nem o registro, nem a coleção.
# - Escrita que o Ability nega não muda o banco: nem o registro (atributos, ou
#   a existência), nem a contagem do modelo. O status não serve de critério —
#   o active_scaffold recusa um update_column alheio respondendo 200.
#
# O request vai sem parâmetros, salvo onde o active_scaffold precisa de um
# para chegar à autorização (PARAMETROS): a matriz mede quem passa pela porta,
# não o que se consegue gravar com um formulário forjado, que é assunto de
# spec/requests/record_write_spec.rb.
#
# O baseline registra o desfecho de cada rota para cada perfil, inclusive o
# que o Ability permite, para que mudança de comportamento apareça mesmo
# quando não viola regra nenhuma.
module HttpMatrix
  # Controllers sem modelo do active_scaffold que ainda assim abrem registro
  # pelo :id: o modelo do registro, e quem pode abri-lo. O StudentEnrollment
  # autoriza a classe (:student_enrollment) e confere o dono no controller.
  REGISTROS_SEM_SCAFFOLD = {
    "student_enrollment" => {
      modelo: Enrollment,
      pode: lambda do |ability, action, user, enrollment|
        ability.can?(action, :student_enrollment) &&
          enrollment.student&.user_id == user&.id && enrollment.enrollment_status&.user
      end,
    },
  }.freeze

  # O update_column e o render_field leem a coluna antes de carregar o
  # registro: sem ela, o request quebra antes da autorização e não diz nada.
  # A coluna é uma de texto do próprio modelo, que o scaffold conhece.
  PARAMETROS = {
    "update_column" => ->(coluna) { { column: coluna, value: "Alterado pela matriz" } },
    "render_field" => ->(coluna) { { column: coluna, update_column: coluna } },
  }.freeze

  ABRE = /\A(2\d\d|3\d\d)/
  RECUSA_POR_REDIRECIONAMENTO = ["302 /users/sign_in"].freeze

  def matriz_http(rotulos)
    perfis = rotulos.map { |rotulo| perfil(rotulo) }
    routes = RouteProbe.routes
    extra = { admission_id: @labels.key("processo").id }
    celulas = Hash.new { |hash, route| hash[route] = {} }
    violacoes = []

    perfis.each do |p|
      user = vestir_perfil(p)
      ability = Ability.new(user)
      routes.each do |route|
        celulas[route][p.first] = alvos(route).map do |record, nome|
          visita = visitar(route, record, nome, user, ability, extra)
          violacao = violacao(route, visita)
          violacoes << "#{p.first} | #{route} | #{nome} => #{violacao}" if violacao
          visita
        end
      end
    end

    [render_matriz(routes, celulas, perfis.map(&:first)), violacoes]
  end

  def modelo_da_rota(route)
    REGISTROS_SEM_SCAFFOLD.dig(route.controller, :modelo) || RouteProbe.model_for(route.controller)
  end

  # A rota de listagem aceita :id (o pai de um scaffold aninhado), mas lista a
  # coleção: o registro do :id não é o que ela mostra.
  def por_registro?(route)
    route.journey.required_parts.include?(:id) && route.action != "index"
  end

  # { registro => nome }. Rota de coleção: um alvo nil. Rota por registro de
  # modelo sem registro rotulado: o primeiro do banco, se houver.
  def alvos(route)
    return { nil => "coleção" } unless por_registro?(route)

    model = modelo_da_rota(route)
    return { nil => "sem modelo" } if model.nil?

    rotulados = @labels.select { |record, _| record.instance_of?(model) && record.persisted? }
    return rotulados if rotulados.any?

    primeiro = model.unscoped.first
    primeiro ? { primeiro => "(primeiro #{model.name})" } : { nil => "(nenhum #{model.name})" }
  end

  def pode?(route, record, user, ability)
    return if RouteProbe.aberta?(route)

    action = route.action.to_sym
    especial = REGISTROS_SEM_SCAFFOLD[route.controller]
    return especial[:pode].call(ability, action, user, record) if especial && record

    sujeito = record || modelo_da_rota(route)
    return if sujeito.nil?

    ability.can?(action, sujeito)
  end

  # O login grava o rastreio do Devise no usuário a cada request, e o
  # PaperTrail registra a gravação: nem uma coisa nem outra é a rota escrevendo.
  RASTREIO_DO_LOGIN = %w[
    sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip updated_at
  ].freeze
  MODELOS_DE_REGISTRO = [Version].freeze

  # O que uma escrita pode ter mudado: os atributos do registro (nil se sumiu),
  # ou a contagem do modelo, numa rota de coleção.
  def rastro(route, record)
    return record.class.unscoped.find_by(id: record.id)&.attributes&.except(*RASTREIO_DO_LOGIN) if record

    model = modelo_da_rota(route)
    model.unscoped.count unless model.nil? || MODELOS_DE_REGISTRO.include?(model)
  end

  def coluna_de_texto(route)
    config = RouteProbe.model_for(route.controller) && "#{route.controller.camelize}Controller".constantize.active_scaffold_config
    return if config.nil?

    config.model.columns.find do |column|
      %i[string text].include?(column.type) && column.name != "id" && config.columns[column.name]
    end&.name
  end

  def parametros(route)
    gerador = PARAMETROS[route.action]
    coluna = gerador && coluna_de_texto(route)
    coluna ? gerador.call(coluna) : {}
  end

  def visitar(route, record, nome, user, ability, extra)
    sign_out :user
    sign_in user if user
    path = route_path(route, id: record&.id || 0, extra: extra)
    params = parametros(route)
    visita = { nome: nome, pode: pode?(route, record, user, ability) }
    ActiveRecord::Base.transaction(requires_new: true) do
      antes = rastro(route, record)
      visita[:desfecho] = probe_outcome(route) do
        process(route.verb.downcase.to_sym, path, params: params, xhr: params.any?,
          env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR })
      end
      visita[:mudou] = antes != rastro(route, record)
      raise ActiveRecord::Rollback
    end
    visita
  end

  def violacao(route, visita)
    return unless visita[:pode] == false

    if route.verb == "GET"
      abriu = visita[:desfecho].match?(ABRE) && !RECUSA_POR_REDIRECIONAMENTO.include?(visita[:desfecho])
      "abriu (#{visita[:desfecho]})" if abriu
    elsif visita[:mudou]
      "mudou o banco (#{visita[:desfecho]})"
    end
  end

  # Uma linha por rota; os perfis de desfecho idêntico ficam juntos.
  def render_matriz(routes, celulas, rotulos)
    linhas = routes.map do |route|
      grupos = rotulos.group_by { |rotulo| assinatura(celulas[route][rotulo]) }
      "#{route} | #{grupos.map { |assin, perfis| "#{perfis.join(', ')}: #{assin}" }.join(' | ')}"
    end
    "#{linhas.join("\n")}\n"
  end

  def assinatura(visitas)
    texto = ->(v) { "#{v[:desfecho]}#{marca(v[:pode])}#{' [mudou]' if v[:mudou]}" }
    textos = visitas.map(&texto)
    return textos.first if visitas.size == 1
    return "todos: #{textos.first}" if textos.uniq.size == 1

    visitas.map { |v| "#{v[:nome]}=#{texto.call(v)}" }.join(", ")
  end

  def marca(pode)
    { true => " (pode)", false => " (nega)", nil => "" }[pode]
  end
end

RSpec.shared_examples "matriz HTTP" do |golden, rotulos|
  include GoldenMaster
  include AbilityDataset
  include RouteProbe
  include HttpMatrix

  before(:each) do
    travel_to GoldenMaster::FROZEN_AT
    build_ability_dataset
  end
  after(:each) { travel_back }

  it "não abre nem muda o que o Ability nega, e mantém o baseline" do
    matriz, violacoes = matriz_http(rotulos)

    expect(violacoes).to be_empty,
      "rotas que contrariam o Ability:\n#{violacoes.join("\n")}"
    expect_matches_golden(golden, matriz, format: :text)
  end
end
