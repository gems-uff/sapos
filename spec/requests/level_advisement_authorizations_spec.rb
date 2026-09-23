# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O formulário de Nível tem subform de credenciamentos, então vários períodos
# do mesmo professor chegam na mesma submissão, e o active_scaffold valida
# todos antes de gravar o primeiro. A validação de interseção compara cada
# linha com as outras do subform em memória, com os valores do envio, e só
# consulta o banco para as demais. Estes exemplos passam pela tela para medir
# esse caminho, e não o do modelo.
RSpec.describe "Credenciamentos pelo subform de Nível", type: :request do
  before(:each) do
    @role_administrador = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_administrador], "adm_nivel@ic.uff.br", "Administrador")
    @professor = FactoryBot.create(:professor)
    sign_in @admin
  end

  def periodo(inicio, fim, id: nil)
    attrs = {
      professor: @professor.id.to_s,
      start_date: I18n.l(inicio),
      end_date: fim ? I18n.l(fim) : ""
    }
    attrs[:id] = id.to_s if id
    attrs
  end

  describe "criação" do
    def criar_nivel(periodos)
      post levels_path, params: {
        record: {
          name: "Nível da sonda",
          default_duration: "24",
          advisement_authorizations: periodos.each_with_index.to_h { |p, i| ["#{1000 + i}", p] }
        }
      }
    end

    it "não grava dois períodos sobrepostos enviados juntos" do
      criar_nivel([
        periodo(Date.new(2020, 1, 1), Date.new(2021, 1, 1)),
        periodo(Date.new(2020, 6, 1), Date.new(2020, 9, 1))
      ])

      expect(Level.where(name: "Nível da sonda")).to be_empty
      expect(AdvisementAuthorization.where(professor: @professor)).to be_empty
    end

    # Controle: sem sobreposição a mesma requisição grava nível e os dois
    # períodos. Sem ele, o vazio acima poderia ser só parâmetro malformado.
    it "grava dois períodos disjuntos enviados juntos" do
      criar_nivel([
        periodo(Date.new(2020, 1, 1), Date.new(2020, 12, 31)),
        periodo(Date.new(2021, 1, 1), nil)
      ])

      level = Level.find_by(name: "Nível da sonda")
      expect(level).to be_present
      expect(level.advisement_authorizations.count).to eq(2)
    end
  end

  describe "edição" do
    before(:each) do
      @level = FactoryBot.create(:level)
      @existente = FactoryBot.create(
        :advisement_authorization, professor: @professor, level: @level,
        start_date: Date.new(2020, 1, 1), end_date: Date.new(2020, 12, 31)
      )
    end

    def atualizar_nivel(periodos, name: @level.name)
      put level_path(@level), params: {
        record: {
          name: name,
          default_duration: @level.default_duration.to_s,
          advisement_authorizations: periodos.each_with_index.to_h { |p, i| [p[:id] || "#{1000 + i}", p] }
        }
      }
    end

    # O caso mais traiçoeiro: a linha nova é validada contra o banco em que a
    # existente ainda tem o fim antigo (passa), e só depois a existente é
    # reaberta. É a regravação da existente que tem de enxergar a nova.
    it "não grava a reabertura de um período que passa a cobrir um período novo" do
      atualizar_nivel([
        periodo(Date.new(2020, 1, 1), nil, id: @existente.id),
        periodo(Date.new(2021, 1, 1), nil)
      ])

      expect(@existente.reload.end_date).to eq(Date.new(2020, 12, 31))
      expect(AdvisementAuthorization.where(professor: @professor).count).to eq(1)
    end

    # Controle: recredenciar depois do período encerrado, na mesma tela, grava.
    it "grava um período novo disjunto do existente" do
      atualizar_nivel([
        periodo(Date.new(2020, 1, 1), Date.new(2020, 12, 31), id: @existente.id),
        periodo(Date.new(2021, 1, 1), nil)
      ])

      expect(AdvisementAuthorization.where(professor: @professor).count).to eq(2)
    end

    # Mover a fronteira entre dois períodos para depois: no fim os dois são
    # disjuntos, mas contra o banco cada linha colidiria com a data ainda
    # gravada da outra. Os dois exemplos só diferem na ordem dos parâmetros.
    describe "fronteira movida entre dois períodos" do
      before(:each) do
        @seguinte = FactoryBot.create(
          :advisement_authorization, professor: @professor, level: @level,
          start_date: Date.new(2021, 1, 1), end_date: nil
        )
      end

      def mover_fronteira(periodos)
        atualizar_nivel(periodos)
        expect(@existente.reload.end_date).to eq(Date.new(2021, 6, 30))
        expect(@seguinte.reload.start_date).to eq(Date.new(2021, 7, 1))
      end

      it "grava com o período anterior primeiro" do
        mover_fronteira([
          periodo(Date.new(2020, 1, 1), Date.new(2021, 6, 30), id: @existente.id),
          periodo(Date.new(2021, 7, 1), nil, id: @seguinte.id)
        ])
      end

      it "grava com o período seguinte primeiro" do
        mover_fronteira([
          periodo(Date.new(2021, 7, 1), nil, id: @seguinte.id),
          periodo(Date.new(2020, 1, 1), Date.new(2021, 6, 30), id: @existente.id)
        ])
      end
    end

    # Remover um período e lançar outro que ocupa as mesmas datas, na mesma
    # submissão: a linha removida não pode barrar a nova.
    it "troca um período por outro que ocupa as mesmas datas" do
      atualizar_nivel([
        periodo(Date.new(2020, 6, 1), nil)
      ])

      expect(AdvisementAuthorization.exists?(@existente.id)).to be(false)
      expect(AdvisementAuthorization.where(professor: @professor).pluck(:start_date))
        .to eq([Date.new(2020, 6, 1)])
    end
  end

  # A main não tinha regra de unicidade, e a migration que criou as datas
  # deixou abertas todas as linhas antigas. Duas linhas do mesmo professor e
  # nível viram dois períodos abertos sobrepostos, gravados sem passar pela
  # validação nova -- daí o save(validate: false).
  describe "duplicata herdada da main" do
    before(:each) do
      @level = FactoryBot.create(:level)
      @antigo = herdado(Date.new(2015, 1, 1))
      @novo = herdado(Date.new(2018, 1, 1))
    end

    def herdado(inicio)
      FactoryBot.build(
        :advisement_authorization, professor: @professor, level: @level,
        start_date: inicio, end_date: nil
      ).tap { |auth| auth.save!(validate: false) }
    end

    def atualizar_nivel(periodos, name: @level.name)
      put level_path(@level), params: {
        record: {
          name: name,
          default_duration: @level.default_duration.to_s,
          advisement_authorizations: periodos.to_h { |p| [p[:id], p] }
        }
      }
    end

    it "salva o nível com outro nome sem mexer nos credenciamentos" do
      atualizar_nivel([
        periodo(Date.new(2015, 1, 1), nil, id: @antigo.id),
        periodo(Date.new(2018, 1, 1), nil, id: @novo.id)
      ], name: "Nível renomeado")

      expect(@level.reload.name).to eq("Nível renomeado")
    end

    # Controle do exemplo acima: sem a duplicata, a mesma requisição renomeia.
    # Sem ele, a recusa poderia ser só parâmetro malformado.
    it "salva o nível com outro nome quando os períodos são disjuntos" do
      @antigo.update_columns(end_date: Date.new(2017, 12, 31))

      atualizar_nivel([
        periodo(Date.new(2015, 1, 1), Date.new(2017, 12, 31), id: @antigo.id),
        periodo(Date.new(2018, 1, 1), nil, id: @novo.id)
      ], name: "Nível renomeado")

      expect(@level.reload.name).to eq("Nível renomeado")
    end

    # Pela tela própria de credenciamentos só a linha editada é validada, e
    # encerrar o antigo antes do novo deixa os dois disjuntos.
    it "encerra o período antigo pela tela de credenciamentos" do
      put advisement_authorization_path(@antigo), params: {
        record: {
          professor: @professor.id.to_s,
          level: @level.id.to_s,
          start_date: I18n.l(Date.new(2015, 1, 1)),
          end_date: I18n.l(Date.new(2017, 12, 31))
        }
      }

      expect(@antigo.reload.end_date).to eq(Date.new(2017, 12, 31))
    end

    # A saída que não apaga histórico: encerrar o antigo antes do novo começar.
    it "encerra o período antigo antes do início do novo" do
      atualizar_nivel([
        periodo(Date.new(2015, 1, 1), Date.new(2017, 12, 31), id: @antigo.id),
        periodo(Date.new(2018, 1, 1), nil, id: @novo.id)
      ])

      expect(@antigo.reload.end_date).to eq(Date.new(2017, 12, 31))
    end

    # Controle do exemplo acima: encerrar só o novo deixa o antigo aberto por
    # cima dele, então editar a duplicata continua exigindo deixá-la disjunta.
    it "recusa encerrar só o novo, ainda coberto pelo antigo aberto" do
      atualizar_nivel([
        periodo(Date.new(2015, 1, 1), nil, id: @antigo.id),
        periodo(Date.new(2018, 1, 1), Date.new(2024, 12, 31), id: @novo.id)
      ])

      expect(@novo.reload.end_date).to be_nil
    end
  end
end
