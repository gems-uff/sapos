# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Fluxo de ponta a ponta do processo seletivo (#681), terceira forma: cartas
# de recomendação obrigatórias, com o recomendador preenchendo pela rota
# pública; comitês de avaliação escolhidos pela linha de pesquisa que o
# candidato marcou; três fases, com uma nota final em cada consolidação; e um
# ranking de bolsas cuja condição cita um campo que o formulário não tem.
#
# Configuração em spec/fixtures/admissions/workflows.json, processo 3.
RSpec.describe "Fluxo do processo seletivo: com cartas e comitês por linha", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "workflow-3-admin@example.com")
    @workflow = AdmissionsWorkflowLoader.load(process_id: 3)
    @process = @workflow.process
    @homologacao, @avaliacao, @entrevista = @workflow.phase_links.map(&:admission_phase)
    @secretary = @workflow.committee_users[1].first
    @linha1 = @workflow.committee_users[3]
    @linha2 = @workflow.committee_users[4]
    allow(Notifier).to receive(:send_emails)
  end

  def position_and_machine(ranking_link, application)
    result = Admissions::AdmissionRankingResult.find_by(
      ranking_config: ranking_link.ranking_config, admission_application: application
    )
    return nil if result.nil? || result.filled_position.value.blank?
    [result.filled_position.value.to_i, result.filled_machine.value]
  end

  def consolidation_value(application, phase, field_name)
    result = application.results.find_by(admission_phase: phase, mode: Admissions::AdmissionPhaseResult::CONSOLIDATION)
    result.filled_form.fields.find { |f| f.form_field.name == field_name }.value
  end

  it "percorre cartas, homologação, avaliação por linha, entrevista e ranking" do
    expect(@process.min_letters).to eq(2)
    expect(@workflow.phase_links.map { |l| l.admission_phase.name }).to eq(["Homologação", "Avaliação por linha", "Entrevista"])
    # A condição do ranking de bolsas cita um campo que a inscrição não tem: o
    # carregador o reserva e o fluxo mostra o efeito no fim.
    expect(@workflow.missing_fields).to eq(["Pedido de bolsa"])

    # ── Inscrição com duas cartas ───────────────────────────────────────────
    letters = ->(prefix) {
      [{ name: "#{prefix} Um", email: "#{prefix.downcase}-um@example.com", telephone: "2199" },
       { name: "#{prefix} Dois", email: "#{prefix.downcase}-dois@example.com" }]
    }
    kim = apply_as_candidate(@process, name: "Kim", email: "kim@example.com",
      values: { "Linha de pesquisa" => "Linha 1" }, letters: letters.call("Rec Kim"))
    lia = apply_as_candidate(@process, name: "Lia", email: "lia@example.com",
      values: { "Linha de pesquisa" => "Linha 2" }, letters: letters.call("Rec Lia"))
    mira = apply_as_candidate(@process, name: "Mira", email: "mira@example.com",
      values: { "Linha de pesquisa" => "Linha 1" }, letters: letters.call("Rec Mira"))
    expect(kim.letter_requests.count).to eq(2)
    expect(kim.missing_letters?).to be true

    # Sem as duas cartas a inscrição não pode ser enviada.
    expect {
      apply_as_candidate(@process, name: "Nilo", email: "nilo@example.com", values: { "Linha de pesquisa" => "Linha 1" })
    }.to raise_error(RuntimeError, /Nilo/)

    # ── Recomendadores preenchem pela rota pública ──────────────────────────
    kim.letter_requests.each do |letter|
      fill_letter_as_recommender(@process, letter, { "Relação com o candidato" => "Orientador", "Avaliação" => "Excelente" })
    end
    fill_letter_as_recommender(@process, mira.letter_requests.first)
    expect(kim.reload.missing_letters?).to be false
    expect(kim.filled_letters).to eq(2)
    expect(mira.reload.filled_letters).to eq(1)

    # ── Homologação ─────────────────────────────────────────────────────────
    shared = Admissions::AdmissionPhaseResult::SHARED
    sign_in @admin
    consolidate_phase_as_staff(@process, nil)
    sign_out @admin
    sign_in @secretary
    submit_phase_form(kim, @homologacao, @homologacao.shared_form, { "Homologação" => "Deferida" }, mode: shared)
    submit_phase_form(lia, @homologacao, @homologacao.shared_form, { "Homologação" => "Deferida" }, mode: shared)
    submit_phase_form(mira, @homologacao, @homologacao.shared_form, { "Homologação" => "Deferida", "Optante por cota racial" => "1" }, mode: shared)
    sign_out @secretary
    sign_in @admin
    consolidate_phase_as_staff(@process, @homologacao)
    sign_out @admin

    # ── Avaliação: o comitê da linha, e só ele, recebe a pendência ──────────
    expect(kim.pendencies.reload.where(admission_phase: @avaliacao).pluck(:user_id)).to contain_exactly(*@linha1.map(&:id))
    expect(lia.pendencies.reload.where(admission_phase: @avaliacao).pluck(:user_id)).to contain_exactly(*@linha2.map(&:id))

    form = @avaliacao.shared_form
    sign_in @linha1.first
    submit_phase_form(kim, @avaliacao, form, { "Nota de formação" => "9", "Nota de produção" => "8", "Nota de experiência" => "10" }, mode: shared)
    submit_phase_form(mira, @avaliacao, form, { "Nota de formação" => "7", "Nota de produção" => "5", "Nota de experiência" => "5" }, mode: shared)
    # Membro de outra linha não tem pendência nem permissão sobre Lia.
    expect {
      submit_phase_form(lia, @avaliacao, form, { "Nota de formação" => "1" }, mode: shared)
    }.to raise_error(RuntimeError, /Lia/)
    sign_out @linha1.first
    sign_in @linha2.first
    submit_phase_form(lia, @avaliacao, form, { "Nota de formação" => "4", "Nota de produção" => "5", "Nota de experiência" => "5" }, mode: shared)
    sign_out @linha2.first

    sign_in @admin
    @process.update!(end_date: Date.yesterday)
    message = consolidate_phase_as_staff(@process, @avaliacao)
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.approved", count: 2))
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.reproved", count: 1))
    expect(consolidation_value(kim, @avaliacao, "Nota final")).to eq("9.0")
    expect(consolidation_value(lia, @avaliacao, "Nota final")).to eq("4.2")
    expect(lia.reload.status).to eq(Admissions::AdmissionApplication::REPROVED)
    expect([kim, mira].map { |a| a.reload.admission_phase }).to all(eq(@entrevista))
    sign_out @admin

    # ── Entrevista: mesmo comitê da linha, outra nota final ─────────────────
    form = @entrevista.shared_form
    sign_in @linha1.last
    submit_phase_form(kim, @entrevista, form, { "Nota de apresentação" => "5", "Nota de arguição" => "4", "Situação sugerida" => "Regular" }, mode: shared)
    submit_phase_form(mira, @entrevista, form, { "Nota de apresentação" => "4", "Nota de arguição" => "3" }, mode: shared)
    sign_out @linha1.last

    sign_in @admin
    message = consolidate_phase_as_staff(@process, @entrevista)
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.approved", count: 2))
    expect(consolidation_value(kim, @entrevista, "Nota final")).to eq("9")
    expect(consolidation_value(mira, @entrevista, "Nota final")).to eq("7")
    expect([kim, mira].map { |a| a.reload.status }).to all(eq(Admissions::AdmissionApplication::APPROVED))

    # ── Rankings ────────────────────────────────────────────────────────────
    # Duas consolidações gravaram "Nota final"; a condição e a coluna do
    # ranking leem a mais recente, a da entrevista.
    vagas, bolsas = @workflow.ranking_links
    expect(position_and_machine(vagas, kim)).to eq([1, "Ampla concorrência"])
    expect(position_and_machine(vagas, mira)).to eq([2, "Ampla concorrência"])
    expect(position_and_machine(vagas, lia)).to be_nil

    # O ranking de bolsas pergunta por um campo que ninguém preencheu: a
    # condição é falsa para todos, e ninguém recebe posição, sem erro.
    expect(bolsas.ranking_config.ranking_columns).to be_empty
    post calculate_ranking_admission_process_path(@process), params: { admission_process_ranking_id: bolsas.id }
    expect(flash[:error]).to be_nil
    expect(position_and_machine(bolsas, kim)).to be_nil
    expect(position_and_machine(bolsas, mira)).to be_nil

    # ── Relatório com as cartas ─────────────────────────────────────────────
    get complete_xls_admission_process_path(@process, format: :xlsx)
    expect(response).to have_http_status(:ok)
    cells = xlsx_representation(response.body)
    expect(cells).to include("Rec Kim Um")
    expect(cells).to include("Excelente")
    expect(cells).to include("Carta de Recomendação 2")
  end
end
