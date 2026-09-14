# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Consolidação de fase pela tela "Situação do processo" (#681): a ação separa
# os candidatos em aprovados, reprovados, cancelados, mantidos, com erro e sem
# comitê; move os aprovados para a fase seguinte, criando as pendências dela;
# recalcula os rankings da fase; e recusa consolidação não parcial fora de
# ordem. Cada exemplo lê o resultado no flash e no banco.
RSpec.describe "Admissions::AdmissionProcesses#consolidate_phase", type: :request do
  I18N = "active_scaffold.admissions/admission_process.consolidate_phase"

  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "consolidate_admin@ic.uff.br")
    sign_in @admin

    @template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
    @process = create_closed_admission_process(@template, simple_url: "consolidate-request")
    @phase1 = add_phase(
      @process, 1, name: "Análise",
      approval_condition: field_condition("nota", Admissions::FormCondition::GE, "7"),
      keep_in_phase_condition: field_condition("nota", Admissions::FormCondition::GE, "5")
    )
    @phase2 = add_phase(@process, 2, name: "Entrevista")
    # Fase seguinte com comitê: sem nenhum, a passagem de fase acusa "comitê
    # incompleto" mesmo quando a fase não tem formulário de comitê.
    @interviewer = professor_user("consolidate-interviewer@ic.uff.br")
    add_committee(@phase1, [@interviewer], name: "Analistas")
    add_committee(@phase2, [@interviewer], name: "Entrevistadores")
  end

  def consolidate(phase, **params)
    post consolidate_phase_admission_process_path(@process),
      params: { consolidate_phase_id: phase&.id || 0 }.merge(params)
  end

  def candidate(grade, phase: @phase1, **attrs)
    create_application(@process, fields: { "nota" => grade }, admission_phase: phase, **attrs)
  end

  describe "consolidação da candidatura (sem fase)" do
    it "aprova as inscrições enviadas e as move para a primeira fase" do
      sent = candidate("8", phase: nil)
      unsent = create_application(@process, filled: false)

      consolidate(nil)

      expect(response).to redirect_to(admission_processes_path)
      expect(flash[:info]).to eq(
        "#{I18n.t("#{I18N}.title", phase: "Candidatura")}. #{I18n.t("#{I18N}.approved", count: 1)}"
      )
      expect(sent.reload.admission_phase).to eq(@phase1)
      expect(sent.status).to be_nil
      expect(unsent.reload.admission_phase).to be_nil
    end

    it "trata a inscrição não enviada conforme o pedido: reprovar ou cancelar" do
      reproved = create_application(@process, filled: false)
      consolidate(nil, fill_pendency: "reprove")
      expect(reproved.reload.status).to eq(Admissions::AdmissionApplication::REPROVED)
      expect(flash[:info]).to include(I18n.t("#{I18N}.reproved", count: 1))

      canceled = create_application(@process, filled: false)
      consolidate(nil, fill_pendency: "cancel")
      expect(canceled.reload.status).to eq(Admissions::AdmissionApplication::CANCELED)
      expect(flash[:info]).to include(I18n.t("#{I18N}.canceled", count: 1))
    end

    it "consolida mesmo assim quando pedido" do
      unsent = create_application(@process, filled: false)
      consolidate(nil, fill_pendency: "consolidate")
      expect(unsent.reload.admission_phase).to eq(@phase1)
    end
  end

  describe "consolidação de uma fase" do
    it "distribui os candidatos e leva só os aprovados adiante" do
      approved = candidate("8")
      kept = candidate("6")
      reproved = candidate("4")

      consolidate(@phase1)

      expect(flash[:info]).to eq([
        I18n.t("#{I18N}.title", phase: "Análise"),
        I18n.t("#{I18N}.not_approved", count: 1),
        I18n.t("#{I18N}.reproved", count: 1),
        I18n.t("#{I18N}.approved", count: 1),
      ].join(". "))
      expect(approved.reload.admission_phase).to eq(@phase2)
      expect(approved.status).to be_nil
      expect(kept.reload.admission_phase).to eq(@phase1)
      expect(kept.status).to be_nil
      expect(reproved.reload.admission_phase).to eq(@phase1)
      expect(reproved.status).to eq(Admissions::AdmissionApplication::REPROVED)
    end

    it "deixa o aprovado na última fase com status aprovado" do
      last = candidate("8", phase: @phase2)
      @phase2.update!(approval_condition: field_condition("nota", Admissions::FormCondition::GE, "7"))
      consolidate(@phase2)
      expect(last.reload.status).to eq(Admissions::AdmissionApplication::APPROVED)
      expect(last.admission_phase).to eq(@phase2)
    end

    it "grava o erro de quem a condição não consegue avaliar" do
      FactoryBot.create(:form_field, name: "sumido")
      @phase1.update!(approval_condition: field_condition("sumido", Admissions::FormCondition::NOT_NULL))
      broken = candidate("8")

      consolidate(@phase1)

      expect(flash[:info]).to include(I18n.t("#{I18N}.errors", count: 1))
      expect(broken.reload.status).to eq(Admissions::AdmissionApplication::ERROR)
      expect(broken.status_message).to include("sumido")
    end

    it "avisa o comitê incompleto na fase seguinte e cria as pendências dela" do
      @phase2.update!(member_form: create_admission_template("Parecer", { "p" => Admissions::FormField::STRING }))
      Admissions::AdmissionPhaseCommittee.where(admission_phase: @phase2).destroy_all
      approved = candidate("8")

      consolidate(@phase1)

      expect(flash[:info]).to include(I18n.t("#{I18N}.missing_committee", count: 1))
      expect(approved.reload.admission_phase).to eq(@phase2)
      expect(approved.pendencies.where(admission_phase: @phase2, mode: Admissions::AdmissionPendency::MEMBER, user_id: nil)).to exist
    end

    it "marca com erro quem a condição de comitê da fase seguinte não consegue avaliar" do
      FactoryBot.create(:form_field, name: "sumido2")
      @phase2.update!(member_form: create_admission_template("Parecer", { "p" => Admissions::FormField::STRING }))
      Admissions::AdmissionPhaseCommittee.where(admission_phase: @phase2).destroy_all
      add_committee(
        @phase2, [professor_user("consolidate-member@ic.uff.br")],
        form_condition: field_condition("sumido2", Admissions::FormCondition::NOT_NULL)
      )
      approved = candidate("8")

      consolidate(@phase1)

      expect(flash[:info]).to include(I18n.t("#{I18N}.errors", count: 1))
      expect(flash[:info]).not_to include(I18n.t("#{I18N}.approved", count: 1))
      approved.reload
      expect(approved.status).to eq(Admissions::AdmissionApplication::ERROR)
      expect(approved.status_message).to include("sumido2")
      expect(approved.admission_phase).to eq(@phase1)
    end

    it "recalcula os rankings ligados à fase" do
      ranking = FactoryBot.create(:ranking_config, name: "Geral", default_column: "nota")
      ranking.ranking_columns.first.update!(order: Admissions::RankingColumn::DESC)
      FactoryBot.create(
        :admission_process_ranking, admission_process: @process, ranking_config: ranking,
        admission_phase: @phase1, order: 1
      )
      first = candidate("9")
      second = candidate("8")

      consolidate(@phase1)

      positions = Admissions::AdmissionRankingResult.where(ranking_config: ranking).to_h do |result|
        [result.admission_application_id, result.filled_position.value]
      end
      expect(positions).to eq({ first.id => "1", second.id => "2" })
    end

    context "com pendências na fase" do
      before(:each) do
        @phase1.update!(shared_form: create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING }))
        @pending = candidate("8")
        @phase1.create_pendencies_for_candidate(@pending)
        expect(@pending.pendencies.shared_pendency(@phase1.id)).to exist
      end

      it "mantém o candidato pendente na fase por padrão" do
        consolidate(@phase1)
        expect(@pending.reload.admission_phase).to eq(@phase1)
        expect(@pending.status).to be_nil
        expect(flash[:info]).to eq(I18n.t("#{I18N}.title", phase: "Análise"))
      end

      it "consolida, reprova ou cancela o pendente conforme o pedido" do
        consolidate(@phase1, shared_pendency: "consolidate")
        expect(@pending.reload.admission_phase).to eq(@phase2)

        other = candidate("8")
        @phase1.create_pendencies_for_candidate(other)
        consolidate(@phase1, shared_pendency: "reprove")
        expect(other.reload.status).to eq(Admissions::AdmissionApplication::REPROVED)

        third = candidate("8")
        @phase1.create_pendencies_for_candidate(third)
        consolidate(@phase1, shared_pendency: "cancel")
        expect(third.reload.status).to eq(Admissions::AdmissionApplication::CANCELED)
      end
    end
  end

  describe "consolidação não parcial" do
    before(:each) do
      @process.phases.find_by(admission_phase: @phase1).update!(partial_consolidation: false)
    end

    it "é recusada enquanto o edital está aberto" do
      @process.update!(end_date: Date.today + 1.day, edit_date: Date.today + 2.days)
      candidate("8")
      consolidate(@phase1)
      expect(flash[:error]).to eq(I18n.t("#{I18N}.open_process_error"))
    end

    it "é recusada com candidatura enviada ainda não consolidada" do
      candidate("8")
      candidate("8", phase: nil)
      consolidate(@phase1)
      expect(flash[:error]).to eq(I18n.t("#{I18N}.non_consolidated_error", count: 1, phase_name: "Candidatura"))
    end

    it "é recusada com pendência na própria fase" do
      @phase1.update!(shared_form: create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING }))
      pending = candidate("8")
      @phase1.create_pendencies_for_candidate(pending)
      consolidate(@phase1)
      expect(flash[:error]).to eq(I18n.t("#{I18N}.pendencies_in_current_error", count: 1, phase_name: "Análise"))
      expect(pending.reload.admission_phase).to eq(@phase1)
    end

    it "é recusada com candidato não consolidado em fase anterior" do
      @process.phases.find_by(admission_phase: @phase2).update!(partial_consolidation: false)
      candidate("6")
      candidate("8", phase: @phase2)
      consolidate(@phase2)
      expect(flash[:error]).to eq(I18n.t("#{I18N}.non_consolidated_error", count: 1, phase_name: "Análise"))
    end

    it "passa quando tudo antes está consolidado" do
      approved = candidate("8")
      consolidate(@phase1)
      expect(flash[:error]).to be_nil
      expect(approved.reload.admission_phase).to eq(@phase2)
    end
  end

  describe "resposta" do
    it "mostra o resumo por grupo quando pedido por xhr" do
      approved = candidate("8")
      reproved = candidate("4")

      post consolidate_phase_admission_process_path(@process),
        params: { consolidate_phase_id: @phase1.id, show_summary: "1" }, xhr: true

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
      expect(response.body).to include(approved.token)
      expect(response.body).to include(reproved.token)
      expect(response.body).to include(I18n.t("#{I18N}.approved", count: 1))
    end

    it "fecha o formulário e recarrega a lista quando não há resumo" do
      candidate("8")
      post consolidate_phase_admission_process_path(@process),
        params: { consolidate_phase_id: @phase1.id }, xhr: true
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("action_link.close()")
    end
  end

  describe "telas auxiliares" do
    it "phase_status abre a situação do processo" do
      candidate("8")
      get phase_status_admission_process_path(@process)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Análise")
    end

    it "rankings abre a tela de rankings" do
      ranking = FactoryBot.create(:ranking_config, name: "Geral", default_column: "nota")
      FactoryBot.create(:admission_process_ranking, admission_process: @process, ranking_config: ranking, order: 1)
      get rankings_admission_process_path(@process)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Geral")
    end
  end
end
