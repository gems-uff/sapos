# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Cantos do processo seletivo sem cobertura (#720): o identificador de processo
# sem URL simples, a fase corrente pela data de inicio das fases, a colisao de
# token de candidatura e de carta, e o ranking configurado para levantar
# excecao quando a condicao cita campo que o candidato nao tem.
RSpec.describe Admissions::AdmissionProcess, "cantos", type: :model do
  describe "#simple_id" do
    before(:each) do
      @processo = FactoryBot.create(
        :admission_process, simple_url: nil,
        start_date: Date.current - 30.days, end_date: Date.current - 1.day
      )
    end

    it "usa o id quando nao ha URL simples" do
      expect(@processo.simple_id).to eq(@processo.id.to_s)
    end

    it "acrescenta Fechado ao id no modo optional_show quando o processo fechou" do
      expect(@processo.simple_id(closed_behavior: :optional_show))
        .to eq("#{@processo.id} (#{Admissions::AdmissionProcess.record_i18n_attr("is_closed?")})")
    end
  end

  describe "#current_phase" do
    before(:each) do
      @processo = FactoryBot.create(:admission_process)
      @analise = FactoryBot.create(:admission_phase, name: "Analise")
      @entrevista = FactoryBot.create(:admission_phase, name: "Entrevista")
      FactoryBot.create(:admission_process_phase, admission_process: @processo, admission_phase: @analise,
        order: 1, start_date: Date.new(2024, 3, 1))
      FactoryBot.create(:admission_process_phase, admission_process: @processo, admission_phase: @entrevista,
        order: 2, start_date: Date.new(2024, 4, 1))
    end

    it "devolve a ultima fase ja iniciada na data" do
      expect(@processo.current_phase(date: Date.new(2024, 3, 15))).to eq(@analise)
      expect(@processo.current_phase(date: Date.new(2024, 4, 1))).to eq(@entrevista)
    end

    it "devolve nil antes da primeira fase" do
      expect(@processo.current_phase(date: Date.new(2024, 2, 1))).to be_nil
    end

    it "usa a data de hoje quando nao recebe data" do
      expect(@processo.current_phase).to eq(@entrevista)
    end
  end
end

RSpec.describe "Colisao de token", type: :model do
  it "sorteia de novo o token de candidatura que ja existe ou repete o prefixo no processo" do
    processo = FactoryBot.create(:admission_process)
    existente = FactoryBot.create(:admission_application, admission_process: processo)
    mesmo_prefixo = "#{existente.token[..6]}ZZZZZ-ZZZZZZ"
    novo = "BBBBBB-BBBBBB-BBBBBB"
    candidatura = FactoryBot.build(:admission_application, admission_process: processo, email: "colisao-720@example.com")
    allow(candidatura).to receive(:generate_token).and_return(existente.token, mesmo_prefixo, novo)

    candidatura.save!

    expect(candidatura.token).to eq(novo)
    expect(candidatura).to have_received(:generate_token).exactly(3).times
  end

  it "sorteia de novo o token de acesso de carta que ja existe" do
    existente = FactoryBot.create(:letter_request)
    allow(SecureRandom).to receive(:urlsafe_base64).and_return(existente.access_token, "token-novo-720")

    carta = FactoryBot.create(:letter_request, admission_application: existente.admission_application)

    expect(carta.access_token).to eq("token-novo-720")
  end
end

RSpec.describe Admissions::AdmissionProcessRanking, "condicao invalida", type: :model do
  before(:each) do
    @processo = FactoryBot.create(:admission_process)
    @ranking = FactoryBot.create(:ranking_config, default_column: "nota_ranking_720")
    # O campo existe em outro template: a condicao e valida, mas o candidato
    # nao o preencheu.
    FactoryBot.create(:form_field, name: "campo_ausente_720")
    @ranking.update!(form_condition: Admissions::FormCondition.create!(
      mode: Admissions::FormCondition::CONDITION, field: "campo_ausente_720",
      condition: Admissions::FormCondition::EQUALS, value: "1"
    ))
    create_ranked_candidates(
      admission_process: @processo, ranking_config: @ranking, values: ["10", "5"],
      columns: [{ name: "nota_ranking_720", type: Admissions::FormField::NUMBER }]
    )
    @ligacao = FactoryBot.create(:admission_process_ranking, admission_process: @processo, ranking_config: @ranking)
  end

  [Admissions::RankingConfig::EXCEPTION_CONDITION, Admissions::RankingConfig::EXCEPTION_ON_PRECONDITION].each do |comportamento|
    it "levanta citando a precondicao quando o comportamento e #{comportamento}" do
      @ranking.update!(behavior_on_invalid_condition: comportamento)

      expect { @ligacao.reload.generate_ranking }.to raise_error(Exceptions::MissingFieldException) do |erro|
        expect(erro.message).to include("campo_ausente_720")
        expect(erro.message).to include(Admissions::FormCondition::RAISE_PRECONDITION)
      end
    end
  end

  it "ignora o candidato sem levantar quando o comportamento e ignorar" do
    expect(@ligacao.generate_ranking).to eq([])
  end
end
