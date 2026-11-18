# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Ao mover um membro de comissao, ou trocar a fase de uma comissao de fase, o
# after_commit recalcula as pendencias do destino e deveria recalcular as da
# origem. Ele procura a origem com previous_changes.try(:admission_committee)
# (e :admission_phase), mas previous_changes e um Hash, que nao responde a
# esses metodos: a origem nunca e recalculada, e a pendencia de quem saiu fica.
RSpec.describe "Recalculo de pendencias ao mover comissao", type: :model do
  before(:each) do
    @recalculadas = []
    recalculadas = @recalculadas
    allow_any_instance_of(Admissions::AdmissionPhase).to receive(:update_pendencies) do |fase|
      recalculadas << fase.id
    end
    @fase_a = FactoryBot.create(:admission_phase)
    @fase_b = FactoryBot.create(:admission_phase)
    @comissao_a = FactoryBot.create(:admission_committee)
    @comissao_b = FactoryBot.create(:admission_committee)
    @fase_comissao_a = FactoryBot.create(:admission_phase_committee,
      admission_phase: @fase_a, admission_committee: @comissao_a)
    FactoryBot.create(:admission_phase_committee,
      admission_phase: @fase_b, admission_committee: @comissao_b)
    @membro = FactoryBot.create(:admission_committee_member, admission_committee: @comissao_a)
    @recalculadas.clear
  end

  describe "membro que muda de comissao" do
    # Recarregada: o after_commit da criacao da comissao ja carregou (vazia) a
    # associacao admission_phase_committees do objeto em memoria.
    before(:each) { @membro.reload.update!(admission_committee: @comissao_b.reload) }

    # Controle: o destino e recalculado.
    it "recalcula as pendencias da fase da comissao nova" do
      expect(@recalculadas).to include(@fase_b.id)
    end

    it "recalcula as pendencias da fase da comissao antiga", pending: "issue #730" do
      expect(@recalculadas).to include(@fase_a.id)
    end
  end

  describe "comissao de fase que muda de fase" do
    before(:each) { @fase_comissao_a.update!(admission_phase: @fase_b) }

    it "recalcula as pendencias da fase nova" do
      expect(@recalculadas).to include(@fase_b.id)
    end

    it "recalcula as pendencias da fase antiga", pending: "issue #730" do
      expect(@recalculadas).to include(@fase_a.id)
    end
  end
end
