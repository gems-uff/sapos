# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O formulário de Professor tem subform de credenciamentos, como o de Nível,
# mas as linhas do envio são do mesmo professor e variam no nível. A
# validação de interseção tem de enxergar as linhas em memória deste subform
# também, e a linha que sai dele tem de ser apagada: o professor não apaga
# credenciamento ao ser excluído (restrict_with_exception), e o writer da
# associação, sem destroy, anularia professor_id. Estes exemplos passam pela
# tela para medir esse caminho, e não o do modelo.
RSpec.describe "Credenciamentos pelo subform de Professor", type: :request do
  before(:each) do
    @role_administrador = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_administrador], "adm_professor@ic.uff.br", "Administrador")
    @mestrado = FactoryBot.create(:level)
    @doutorado = FactoryBot.create(:level)
    sign_in @admin
  end

  def periodo(nivel, inicio, fim, id: nil)
    attrs = {
      level: nivel.id.to_s,
      start_date: I18n.l(inicio),
      end_date: fim ? I18n.l(fim) : ""
    }
    attrs[:id] = id.to_s if id
    attrs
  end

  def credenciamentos(periodos)
    periodos.each_with_index.to_h { |p, i| [p[:id] || "#{1000 + i}", p] }
  end

  describe "criação" do
    def criar_professor(periodos)
      post professors_path, params: {
        record: {
          name: "Professor da sonda",
          cpf: "999.999.999-99",
          advisement_authorizations: credenciamentos(periodos)
        }
      }
      Professor.find_by(name: "Professor da sonda")
    end

    it "não grava dois períodos sobrepostos no mesmo nível enviados juntos" do
      professor = criar_professor([
        periodo(@mestrado, Date.new(2020, 1, 1), Date.new(2021, 1, 1)),
        periodo(@mestrado, Date.new(2020, 6, 1), Date.new(2020, 9, 1))
      ])

      expect(professor).to be_nil
      expect(AdvisementAuthorization.where(level: @mestrado)).to be_empty
    end

    # Controle: sem sobreposição a mesma requisição grava professor e os dois
    # períodos. Sem ele, o vazio acima poderia ser só parâmetro malformado.
    it "grava dois períodos disjuntos no mesmo nível enviados juntos" do
      professor = criar_professor([
        periodo(@mestrado, Date.new(2020, 1, 1), Date.new(2020, 12, 31)),
        periodo(@mestrado, Date.new(2021, 1, 1), nil)
      ])

      expect(professor.advisement_authorizations.count).to eq(2)
    end

    # O grupo é (professor, nível): as mesmas datas em níveis diferentes não
    # se cruzam. O pai em memória não pode apagar o nível da comparação.
    it "grava as mesmas datas em níveis diferentes" do
      professor = criar_professor([
        periodo(@mestrado, Date.new(2020, 1, 1), nil),
        periodo(@doutorado, Date.new(2020, 1, 1), nil)
      ])

      expect(professor.advisement_authorizations.map(&:level)).to contain_exactly(@mestrado, @doutorado)
    end
  end

  describe "edição" do
    before(:each) do
      @professor = FactoryBot.create(:professor)
      @existente = FactoryBot.create(
        :advisement_authorization, professor: @professor, level: @mestrado,
        start_date: Date.new(2020, 1, 1), end_date: Date.new(2020, 12, 31)
      )
    end

    def atualizar_professor(periodos, name: @professor.name)
      put professor_path(@professor), params: {
        record: { name: name, advisement_authorizations: credenciamentos(periodos) }
      }
    end

    # A linha nova é validada contra o banco em que a existente ainda tem o
    # fim antigo (passa), e só depois a existente é reaberta. É a regravação
    # da existente que tem de enxergar a nova, em memória.
    it "não grava a reabertura de um período que passa a cobrir um período novo" do
      atualizar_professor([
        periodo(@mestrado, Date.new(2020, 1, 1), nil, id: @existente.id),
        periodo(@mestrado, Date.new(2021, 1, 1), nil)
      ])

      expect(@existente.reload.end_date).to eq(Date.new(2020, 12, 31))
      expect(@professor.advisement_authorizations.reload.count).to eq(1)
    end

    # Controle: recredenciar depois do período encerrado, na mesma tela, grava.
    it "grava um período novo disjunto do existente" do
      atualizar_professor([
        periodo(@mestrado, Date.new(2020, 1, 1), Date.new(2020, 12, 31), id: @existente.id),
        periodo(@mestrado, Date.new(2021, 1, 1), nil)
      ])

      expect(@professor.advisement_authorizations.reload.count).to eq(2)
    end

    # O período que cruza vem do banco, gravado por outra tela: a linha nova
    # do subform tem de ser comparada também com o que não veio no envio.
    it "não grava um período novo que cruza o do banco" do
      atualizar_professor([
        periodo(@mestrado, Date.new(2020, 1, 1), Date.new(2020, 12, 31), id: @existente.id),
        periodo(@mestrado, Date.new(2020, 6, 1), nil)
      ])

      expect(@professor.advisement_authorizations.reload.count).to eq(1)
    end

    describe "fronteira movida entre dois períodos" do
      before(:each) do
        @seguinte = FactoryBot.create(
          :advisement_authorization, professor: @professor, level: @mestrado,
          start_date: Date.new(2021, 1, 1), end_date: nil
        )
      end

      def mover_fronteira(periodos)
        atualizar_professor(periodos)
        expect(@existente.reload.end_date).to eq(Date.new(2021, 6, 30))
        expect(@seguinte.reload.start_date).to eq(Date.new(2021, 7, 1))
      end

      it "grava com o período anterior primeiro" do
        mover_fronteira([
          periodo(@mestrado, Date.new(2020, 1, 1), Date.new(2021, 6, 30), id: @existente.id),
          periodo(@mestrado, Date.new(2021, 7, 1), nil, id: @seguinte.id)
        ])
      end

      it "grava com o período seguinte primeiro" do
        mover_fronteira([
          periodo(@mestrado, Date.new(2021, 7, 1), nil, id: @seguinte.id),
          periodo(@mestrado, Date.new(2020, 1, 1), Date.new(2021, 6, 30), id: @existente.id)
        ])
      end
    end

    # O espelho da troca de professor no subform de Nível: a linha muda de
    # nível e outra, nova, ocupa as datas no nível antigo. A cópia no banco da
    # linha que saiu do nível não pode acusar sobreposição.
    it "troca o nível de uma linha e reaproveita as datas no nível antigo" do
      atualizar_professor([
        periodo(@doutorado, Date.new(2020, 1, 1), Date.new(2020, 12, 31), id: @existente.id),
        periodo(@mestrado, Date.new(2020, 1, 1), Date.new(2020, 12, 31))
      ])

      expect(@existente.reload.level).to eq(@doutorado)
      expect(@professor.advisement_authorizations.reload.map(&:level)).to contain_exactly(@mestrado, @doutorado)
    end

    # Remover um período e lançar outro que ocupa as mesmas datas, na mesma
    # submissão: a linha removida não pode barrar a nova.
    it "troca um período por outro que ocupa as mesmas datas" do
      atualizar_professor([
        periodo(@mestrado, Date.new(2020, 6, 1), nil)
      ])

      expect(AdvisementAuthorization.exists?(@existente.id)).to be(false)
      expect(@professor.advisement_authorizations.reload.pluck(:start_date)).to eq([Date.new(2020, 6, 1)])
    end
  end

  describe "remoção pelo subform" do
    before(:each) do
      @professor = FactoryBot.create(:professor)
      @encerrado = FactoryBot.create(
        :advisement_authorization, professor: @professor, level: @mestrado,
        start_date: Date.new(2015, 1, 1), end_date: Date.new(2017, 12, 31)
      )
      @vigente = FactoryBot.create(
        :advisement_authorization, professor: @professor, level: @mestrado,
        start_date: Date.new(2018, 1, 1), end_date: nil
      )
    end

    def atualizar_professor(periodos)
      put professor_path(@professor), params: {
        record: { name: @professor.name, advisement_authorizations: credenciamentos(periodos) }
      }
    end

    # O "Remover" do subform tira a linha do envio, e o active_scaffold
    # substitui a associação pelo que chegou. Sem destroy, o writer anula
    # professor_id: a linha some da tela, mas fica no banco sem professor e
    # sem a versão de remoção no paper_trail.
    it "apaga o período removido, com a versão de remoção, sem deixá-lo órfão" do
      atualizar_professor([
        periodo(@mestrado, Date.new(2018, 1, 1), nil, id: @vigente.id)
      ])

      expect(AdvisementAuthorization.exists?(@encerrado.id)).to be(false)
      expect(AdvisementAuthorization.where(professor_id: nil)).to be_empty
      expect(PaperTrail::Version.where(item_type: "AdvisementAuthorization", item_id: @encerrado.id,
                                       event: "destroy")).to exist
      expect(@vigente.reload.professor).to eq(@professor)
    end

    # Controle: reenviar as duas linhas não apaga nada. Sem ele, o sumiço
    # acima poderia vir de qualquer envio, não da remoção.
    it "mantém os dois períodos quando nenhum é removido" do
      atualizar_professor([
        periodo(@mestrado, Date.new(2015, 1, 1), Date.new(2017, 12, 31), id: @encerrado.id),
        periodo(@mestrado, Date.new(2018, 1, 1), nil, id: @vigente.id)
      ])

      expect(@professor.advisement_authorizations.reload).to contain_exactly(@encerrado, @vigente)
    end

    # O apagamento acontece no writer da associação, antes de o professor ser
    # validado. Envio recusado não pode levar o período removido junto.
    it "não apaga o período removido quando o envio é recusado" do
      atualizar_professor([
        periodo(@mestrado, Date.new(2018, 1, 1), nil, id: @vigente.id),
        periodo(@mestrado, Date.new(2019, 1, 1), nil)
      ])

      expect(@professor.advisement_authorizations.reload).to contain_exactly(@encerrado, @vigente)
    end

    it "continua recusando excluir o professor com histórico de credenciamento" do
      delete professor_path(@professor)

      expect(Professor.exists?(@professor.id)).to be(true)
      expect(@professor.advisement_authorizations.reload.count).to eq(2)
    end
  end

  # A mesma reprodução dos subforms de Nível e de Filiação: data que o
  # date_picker não entende, numa linha nova, não pode virar período em aberto,
  # nem reabrir o período encerrado. Recusar ou gravar o dia digitado atendem.
  describe "término que o date_picker não entende" do
    before(:each) do
      @professor = FactoryBot.create(:professor)
    end

    def atualizar_professor(periodos)
      put professor_path(@professor), params: {
        record: { name: @professor.name, advisement_authorizations: credenciamentos(periodos) }
      }
    end

    { "31/02/2026" => nil, "2020" => nil, "banana" => nil,
      "15.03.2024" => Date.new(2024, 3, 15), "2024-03-15" => Date.new(2024, 3, 15) }
      .each do |entrada, dia_digitado|
        it "não acrescenta o período como aberto: #{entrada.inspect}" do
          atualizar_professor([
            periodo(@mestrado, Date.new(2020, 1, 1), nil).merge(end_date: entrada)
          ])

          gravados = @professor.advisement_authorizations.reload.map(&:end_date)
          expect([[], [dia_digitado].compact]).to include(gravados)
        end

        it "não reabre o período encerrado: #{entrada.inspect}" do
          encerrado = FactoryBot.create(
            :advisement_authorization, professor: @professor, level: @mestrado,
            start_date: Date.new(2020, 1, 1), end_date: Date.new(2022, 1, 1)
          )
          atualizar_professor([
            periodo(@mestrado, Date.new(2020, 1, 1), nil, id: encerrado.id).merge(end_date: entrada)
          ])

          expect([Date.new(2022, 1, 1), dia_digitado].compact).to include(encerrado.reload.end_date)
        end
      end
  end

  # Duplicatas abertas gravadas sem validação (script, console): editar o
  # professor sem tocar nelas não pode ficar preso. O mesmo cenário do Nível.
  describe "períodos sobrepostos gravados sem validação" do
    before(:each) do
      @professor = FactoryBot.create(:professor)
      @antigo = herdado(Date.new(2015, 1, 1))
      @novo = herdado(Date.new(2018, 1, 1))
    end

    def herdado(inicio)
      FactoryBot.build(
        :advisement_authorization, professor: @professor, level: @mestrado,
        start_date: inicio, end_date: nil
      ).tap { |auth| auth.save!(validate: false) }
    end

    def renomear(fim_do_antigo)
      put professor_path(@professor), params: {
        record: {
          name: "Professor renomeado",
          advisement_authorizations: {
            @antigo.id.to_s => periodo(@mestrado, Date.new(2015, 1, 1), fim_do_antigo, id: @antigo.id),
            @novo.id.to_s => periodo(@mestrado, Date.new(2018, 1, 1), nil, id: @novo.id)
          }
        }
      }
    end

    it "salva o professor com outro nome sem mexer nos credenciamentos" do
      renomear(nil)

      expect(@professor.reload.name).to eq("Professor renomeado")
    end

    # Controle: a mesma requisição, encerrando o antigo antes do novo, chega
    # aos credenciamentos. Sem ele, o exemplo acima passaria com um subform
    # que o envio nem alcança.
    it "encerra o período antigo antes do início do novo" do
      renomear(Date.new(2017, 12, 31))

      expect(@antigo.reload.end_date).to eq(Date.new(2017, 12, 31))
    end
  end
end
