# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Fluxo de ponta a ponta do processo seletivo (#681), segunda forma: a
# avaliação é INDIVIDUAL, um formulário por membro do comitê, e a consolidação
# tira a média dos pareceres; a aprovação exige duas condições ao mesmo tempo;
# o ranking de vagas tem quatro colunas de desempate, a última a idade; e o
# edital permite desfazer a consolidação.
#
# Configuração em spec/fixtures/admissions/workflows.json, processo 2.
RSpec.describe "Fluxo do processo seletivo: avaliação individual", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "workflow-2-admin@example.com")
    @workflow = AdmissionsWorkflowLoader.load(process_id: 2)
    @process = @workflow.process
    @homologacao, @avaliacao = @workflow.phase_links.map(&:admission_phase)
    @secretary = @workflow.committee_users[1].first
    @evaluators = @workflow.committee_users[2]
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

  it "avalia por membro, consolida pela média, classifica com desempate e desfaz" do
    expect(@workflow.missing_fields).to eq([])
    expect(@avaliacao.member_form).to be_present
    expect(@avaliacao.shared_form).to be_nil
    expect(@evaluators.size).to eq(3)

    gil = apply_as_candidate(@process, name: "Gil", email: "gil@example.com", values: { "Data de nascimento" => "01/01/1990" })
    hugo = apply_as_candidate(@process, name: "Hugo", email: "hugo@example.com", values: { "Data de nascimento" => "01/01/1992" })
    iris = apply_as_candidate(@process, name: "Iris", email: "iris@example.com", values: { "Data de nascimento" => "01/01/1994" })
    # Mesmas notas de Gil, mais nova: só a idade os separa no ranking.
    joana = apply_as_candidate(@process, name: "Joana", email: "joana@example.com", values: { "Data de nascimento" => "01/01/2000" })
    candidates = [gil, hugo, iris, joana]

    sign_in @admin
    consolidate_phase_as_staff(@process, nil)
    sign_out @admin

    sign_in @secretary
    candidates.each do |application|
      submit_phase_form(application, @homologacao, @homologacao.shared_form, { "Homologação" => "Deferida" },
        mode: Admissions::AdmissionPhaseResult::SHARED)
    end
    sign_out @secretary

    sign_in @admin
    consolidate_phase_as_staff(@process, @homologacao)
    sign_out @admin
    expect(candidates.map { |a| a.reload.admission_phase }).to all(eq(@avaliacao))
    candidates.each do |application|
      expect(application.pendencies.where(admission_phase: @avaliacao, mode: Admissions::AdmissionPendency::MEMBER).pluck(:user_id))
        .to contain_exactly(*@evaluators.map(&:id))
    end

    # ── Cada membro avalia; a pendência individual é de cada um ─────────────
    grades = {
      gil => [[9, 8, 7], [9, 8, 7], [9, 8, 7]],
      hugo => [[9, 9, 5], [9, 9, 5], [9, 9, 5]],
      iris => [[6, 6, 6], [7, 7, 7], [8, 8, 8]],
      joana => [[9, 8, 7], [9, 8, 7], [9, 8, 7]],
    }
    member_form = @avaliacao.member_form
    @evaluators.each_with_index do |evaluator, index|
      sign_in evaluator
      grades.each do |application, per_member|
        formation, experience, project = per_member[index]
        submit_phase_form(application, @avaliacao, member_form, {
          "Nota de formação" => formation.to_s, "Nota de experiência" => experience.to_s,
          "Nota de projeto" => project.to_s, "Parecer" => "Parecer do membro #{index + 1}",
        }, user: evaluator)
      end
      sign_out evaluator
      pending = gil.pendencies.reload.where(admission_phase: @avaliacao, status: Admissions::AdmissionPendency::PENDENT).count
      expect(pending).to eq(@evaluators.size - index - 1)
    end
    expect(gil.evaluations.where(admission_phase: @avaliacao).count).to eq(3)

    # ── Consolidação: médias, nota final e a dupla condição ─────────────────
    sign_in @admin
    @process.update!(end_date: Date.yesterday)
    message = consolidate_phase_as_staff(@process, @avaliacao)
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.approved", count: 3))
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.reproved", count: 1))

    expect(consolidation_value(gil, @avaliacao, "Média de projeto")).to eq("7.0")
    expect(consolidation_value(gil, @avaliacao, "Nota final")).to eq("8.0")
    expect(consolidation_value(iris, @avaliacao, "Média de formação")).to eq("7.0")
    expect(consolidation_value(iris, @avaliacao, "Nota final")).to eq("7.0")
    # Hugo tem nota final 7.67, mas projeto 5.0: a segunda condição reprova.
    expect(consolidation_value(hugo, @avaliacao, "Nota final")).to eq("7.67")
    expect(consolidation_value(hugo, @avaliacao, "Média de projeto")).to eq("5.0")
    expect(hugo.reload.status).to eq(Admissions::AdmissionApplication::REPROVED)
    expect([gil, iris, joana].map { |a| a.reload.status }).to all(eq(Admissions::AdmissionApplication::APPROVED))

    # ── Ranking: empate total entre Gil e Joana, decidido pela idade ────────
    vagas = @workflow.ranking_links.first
    expect(vagas.ranking_config.ranking_columns.map(&:name))
      .to eq(["Nota final", "Média de projeto", "Média de experiência", "Idade"])
    expect(position_and_machine(vagas, gil)).to eq([1, "Ampla concorrência"])
    expect(position_and_machine(vagas, joana)).to eq([2, "Ampla concorrência"])
    expect(position_and_machine(vagas, iris)).to eq([3, "Ampla concorrência"])
    expect(position_and_machine(vagas, hugo)).to be_nil

    # ── Situação do processo e relatório completo ───────────────────────────
    get phase_status_admission_process_path(@process)
    expect(response).to have_http_status(:ok)
    get complete_xls_admission_process_path(@process, format: :xlsx)
    expect(response).to have_http_status(:ok)
    cells = xlsx_representation(response.body)
    expect(cells).to include("Parecer do membro 3")
    expect(cells).to include("Média de projeto")

    # ── Desfazer a consolidação de Hugo e reconsolidar ──────────────────────
    put undo_consolidation_admission_application_path(hugo), xhr: true
    expect(response).to have_http_status(:ok)
    hugo.reload
    expect(hugo.status).to be_nil
    expect(hugo.admission_phase).to eq(@avaliacao)
    expect(hugo.results.where(admission_phase: @avaliacao, mode: Admissions::AdmissionPhaseResult::CONSOLIDATION)).to be_empty
    expect(hugo.evaluations.count).to eq(3)

    message = consolidate_phase_as_staff(@process, @avaliacao)
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.reproved", count: 1))
    expect(hugo.reload.status).to eq(Admissions::AdmissionApplication::REPROVED)
  end
end
