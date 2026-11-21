# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Os selects de busca de orientacoes (ativa, coorientador) e de trancamentos
# (ativo) so oferecem valores conhecidos; o ramo de valor desconhecido, que so
# chega por parametro montado a mao, nunca rodava (#720). Defesa: valor forjado
# nao filtra nada nem quebra a consulta.
RSpec.describe "Valores de busca forjados" do
  describe AdvisementsController do
    before(:each) do
      nivel = FactoryBot.create(:level)
      professor = FactoryBot.create(:professor)
      FactoryBot.create(:advisement_authorization, professor:, level: nivel)
      matricula = ->() { FactoryBot.create(:enrollment, level: nivel) }
      principal = FactoryBot.create(:advisement, professor:, enrollment: matricula.call, main_advisor: true)
      @coorientacao = FactoryBot.create(:advisement, enrollment: Enrollment.find(principal.enrollment_id), main_advisor: false)
      @sem_coorientador = FactoryBot.create(:advisement, professor:, enrollment: matricula.call, main_advisor: true)
      @todas = [principal.id, @coorientacao.id, @sem_coorientador.id]
    end

    def ids(condicao)
      Advisement.where(*condicao).pluck(:id)
    end

    it "orientacao ativa com valor desconhecido devolve o mesmo que 'all'" do
      forjado = ids(described_class.condition_for_active_column(nil, "forjado", nil))

      expect(forjado).to match_array(@todas)
      expect(forjado).to match_array(ids(described_class.condition_for_active_column(nil, "all", nil)))
    end

    it "coorientador com valor desconhecido devolve o mesmo que 'all'" do
      forjado = ids(described_class.condition_for_co_advisor_column(nil, "forjado", nil))

      expect(forjado).to match_array(@todas)
      expect(forjado).to match_array(ids(described_class.condition_for_co_advisor_column(nil, "all", nil)))
    end

    # Controle: o valor conhecido filtra de fato, entao o "igual a all" acima
    # nao e so uma consulta que nunca filtra.
    it "coorientador 'nao' deixa de fora as orientacoes da matricula com coorientador" do
      expect(ids(described_class.condition_for_co_advisor_column(nil, "nao", nil))).to eq([@sem_coorientador.id])
    end
  end

  describe EnrollmentHoldsController do
    before(:each) { @ativo = FactoryBot.create(:enrollment_hold) }

    it "trancamento ativo com valor desconhecido nao filtra" do
      expect(described_class.condition_for_active_column(nil, "forjado", nil)).to be_nil
    end

    it "trancamento ativo '1' filtra pelo trancamento vigente" do
      expect(described_class.condition_for_active_column(nil, "1", nil)).to eq("enrollment_holds.id IN (#{@ativo.id})")
    end
  end
end
