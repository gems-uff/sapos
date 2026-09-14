# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Fluxo de ponta a ponta do processo seletivo (#681), primeira forma: inscrição
# pela rota pública com um campo de cada tipo, consolidação da candidatura,
# homologação pelo comitê num formulário compartilhado com e-mails de resultado
# e campo calculado, avaliação num formulário compartilhado com nota final
# calculada, consolidação não parcial só com o edital fechado, dois rankings em
# sequência (vagas com três seletores e etapa de sobra, e bolsas dependendo da
# posição no primeiro) e os três relatórios.
#
# A configuração vem de spec/fixtures/admissions/workflows.json, processo 1.
# Cada passo passa pela rota que a pessoa usaria, com o papel dela, e as
# asserções são o que o edital promete: quem foi homologado, a nota final de
# cada um, quem ficou em que posição e por qual seletor.
RSpec.describe "Fluxo do processo seletivo: avaliação compartilhada", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "workflow-1-admin@example.com")
    @workflow = AdmissionsWorkflowLoader.load(process_id: 1)
    @process = @workflow.process
    @homologacao, @avaliacao = @workflow.phase_links.map(&:admission_phase)
    @secretary = @workflow.committee_users[1].first
    @evaluators = @workflow.committee_users[2]
    @sent = []
    allow(Notifier).to receive(:send_emails) { |notifications:| @sent.concat(notifications) }
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

  it "percorre inscrição, homologação, avaliação, ranking e relatórios" do
    expect(@workflow.missing_fields).to eq([])
    expect(@workflow.phase_links.map { |l| [l.admission_phase.name, l.partial_consolidation] })
      .to eq([["Homologação", true], ["Avaliação compartilhada", false]])
    expect(@workflow.ranking_links.map { |l| l.ranking_config.name }).to eq(["Vagas", "Bolsas"])

    # ── Inscrição ───────────────────────────────────────────────────────────
    bolsa = "Solicita bolsa?"
    ana = apply_as_candidate(@process, name: "Ana", email: "ana@example.com",
      values: { bolsa => "Sim, ainda não sou aluno", "Data de nascimento" => "10/05/1998" })
    bento = apply_as_candidate(@process, name: "Bento", email: "bento@example.com",
      values: { bolsa => "Não", "Data de nascimento" => "10/05/1995" })
    clara = apply_as_candidate(@process, name: "Clara", email: "clara@example.com",
      values: { bolsa => "Sim, ainda não sou aluno" })
    davi = apply_as_candidate(@process, name: "Davi", email: "davi@example.com", values: { bolsa => "Não" })
    fabio = apply_as_candidate(@process, name: "Fabio", email: "fabio@example.com", values: { bolsa => "Sim, já sou aluno" })
    post admission_path(@process.simple_url), params: { admissions_admission_application: { name: "Eva", email: "eva@example.com" } }
    eva = Admissions::AdmissionApplication.find_by(email: "eva@example.com")

    submitted = [ana, bento, clara, davi, fabio]
    expect(submitted.map { |a| a.filled_form.is_filled }).to all(be true)
    expect(eva.filled_form.is_filled).to be false
    expect(ana.filled_form.fields.count).to eq(@process.form_template.fields.count)
    expect(ana.filled_form.fields.count { |f| f.file.present? }).to eq(2)
    expect(ana.filled_form.fields.find { |f| f.form_field.name == "Formação" }.scholarities.count).to eq(1)
    expect(@sent.count { |n| n[:to] == "ana@example.com" }).to eq(1)

    # ── Consolidação da candidatura: só inscrição enviada entra na fase 1 ────
    sign_in @admin
    consolidate_phase_as_staff(@process, nil)
    expect(submitted.map { |a| a.reload.admission_phase }).to all(eq(@homologacao))
    expect(eva.reload.admission_phase).to be_nil
    submitted.each do |application|
      expect(application.pendencies.where(admission_phase: @homologacao, user: @secretary, mode: Admissions::AdmissionPendency::SHARED, status: Admissions::AdmissionPendency::PENDENT)).to exist
    end
    sign_out @admin

    # ── Homologação pelo comitê ─────────────────────────────────────────────
    sign_in @secretary
    form = @homologacao.shared_form
    shared = Admissions::AdmissionPhaseResult::SHARED
    submit_phase_form(ana, @homologacao, form, { "Homologação" => "Deferida" }, mode: shared)
    submit_phase_form(bento, @homologacao, form, { "Homologação" => "Deferida", "Optante por cota racial" => "1" }, mode: shared)
    submit_phase_form(clara, @homologacao, form, { "Homologação" => "Deferida", "PcD" => "1" }, mode: shared)
    submit_phase_form(davi, @homologacao, form, { "Homologação" => "Indeferida", "Motivo" => "Diploma ausente" }, mode: shared)
    submit_phase_form(fabio, @homologacao, form, { "Homologação" => "Deferida" }, mode: shared)
    expect(ana.pendencies.reload.where(admission_phase: @homologacao).pluck(:status).uniq).to eq([Admissions::AdmissionPendency::OK])
    sign_out @secretary

    # ── Consolidação da homologação: parcial, com e-mails e campo calculado ─
    sign_in @admin
    @sent.clear
    message = consolidate_phase_as_staff(@process, @homologacao)
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.approved", count: 4))
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.reproved", count: 1))

    expect([ana, bento, clara, fabio].map { |a| a.reload.admission_phase }).to all(eq(@avaliacao))
    expect(davi.reload.status).to eq(Admissions::AdmissionApplication::REPROVED)
    expect(davi.admission_phase).to eq(@homologacao)

    homologados = @sent.select { |n| n[:subject] == "Candidatura homologada" }
    expect(homologados.map { |n| n[:to] }).to contain_exactly("ana@example.com", "bento@example.com", "clara@example.com", "fabio@example.com")
    indeferido = @sent.find { |n| n[:subject] == "Candidatura não homologada" }
    expect(indeferido[:to]).to eq("davi@example.com")
    expect(indeferido[:body]).to include("Diploma ausente")
    expect(consolidation_value(ana, @homologacao, "Idade").to_f).to be_within(1).of(((Date.today - Date.new(1998, 5, 10)) / 365.25).to_f)

    [ana, bento, clara, fabio].each do |application|
      expect(application.pendencies.where(admission_phase: @avaliacao, mode: Admissions::AdmissionPendency::SHARED).pluck(:user_id))
        .to contain_exactly(*@evaluators.map(&:id))
    end
    sign_out @admin

    # ── Avaliação: um membro preenche o formulário compartilhado ────────────
    sign_in @evaluators.first
    form = @avaliacao.shared_form
    grades = {
      ana => { "Nota de formação" => "9", "Nota de produção" => "8", "Nota de experiência" => "7" },
      bento => { "Nota de formação" => "7", "Nota de produção" => "6", "Nota de experiência" => "6" },
      clara => { "Nota de formação" => "5", "Nota de produção" => "9", "Nota de experiência" => "9" },
      fabio => { "Nota de formação" => "8", "Nota de produção" => "8", "Nota de experiência" => "8" },
    }
    grades.each { |application, values| submit_phase_form(application, @avaliacao, form, values, mode: shared) }
    # Preenchido por um membro, a pendência compartilhada se resolve para todos.
    expect(ana.pendencies.reload.where(admission_phase: @avaliacao).pluck(:status).uniq).to eq([Admissions::AdmissionPendency::OK])
    sign_out @evaluators.first

    # ── Consolidação da avaliação: não parcial, exige edital fechado ────────
    sign_in @admin
    post consolidate_phase_admission_process_path(@process), params: { consolidate_phase_id: @avaliacao.id }
    expect(flash[:error]).to eq(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.open_process_error"))
    expect(ana.reload.status).to be_nil

    @process.update!(end_date: Date.yesterday)
    message = consolidate_phase_as_staff(@process, @avaliacao)
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.approved", count: 3))
    expect(message).to include(I18n.t("active_scaffold.admissions/admission_process.consolidate_phase.reproved", count: 1))

    # Nota final = (8 × formação + produção + experiência) / 10
    expect(consolidation_value(ana, @avaliacao, "Nota final")).to eq("8.7")
    expect(consolidation_value(bento, @avaliacao, "Nota final")).to eq("6.8")
    expect(consolidation_value(clara, @avaliacao, "Nota final")).to eq("5.8")
    expect(consolidation_value(fabio, @avaliacao, "Nota final")).to eq("8.0")
    expect([ana, bento, fabio].map { |a| a.reload.status }).to all(eq(Admissions::AdmissionApplication::APPROVED))
    expect(clara.reload.status).to eq(Admissions::AdmissionApplication::REPROVED)
    expect(eva.reload.status).to be_nil

    # ── Rankings, na ordem do edital ────────────────────────────────────────
    # A consolidação já recalculou os rankings ligados à fase; recalcular pela
    # tela dá o mesmo resultado.
    vagas, bolsas = @workflow.ranking_links
    [vagas, bolsas].each do |link|
      post calculate_ranking_admission_process_path(@process), params: { admission_process_ranking_id: link.id }
      expect(flash[:error]).to be_nil
    end

    # Vagas: só nota final ≥ 6; quem já é aluno não concorre a vaga. As cotas
    # só entram quando a ampla concorrência esgota, o que não acontece aqui.
    expect(position_and_machine(vagas, ana)).to eq([1, "Ampla concorrência"])
    expect(position_and_machine(vagas, bento)).to eq([2, "Ampla concorrência"])
    expect(position_and_machine(vagas, fabio)).to be_nil
    expect(position_and_machine(vagas, clara)).to be_nil
    expect(position_and_machine(vagas, davi)).to be_nil

    # Bolsas: quem já é aluno, ou quem ficou classificado e pediu bolsa.
    expect(position_and_machine(bolsas, ana)).to eq([1, "Bolsa"])
    expect(position_and_machine(bolsas, fabio)).to eq([2, "Bolsa"])
    expect(position_and_machine(bolsas, bento)).to be_nil

    # ── Relatórios ──────────────────────────────────────────────────────────
    get complete_xls_admission_process_path(@process, format: :xlsx)
    expect(response).to have_http_status(:ok)
    cells = xlsx_representation(response.body)
    expect(cells).to include(ana.token)
    expect(cells).to include("Nota final")
    expect(cells).to include("Posição/Bolsas")
    expect(cells).not_to include(eva.token)

    get complete_pdf_admission_process_path(@process, format: :pdf)
    expect(response).to have_http_status(:ok)
    expect(pdf_representation(response.body)).to include("Ampla concorrência")

    get short_pdf_admission_process_path(@process, format: :pdf)
    expect(response).to have_http_status(:ok)
    expect(pdf_representation(response.body)).to include("Total de Inscritos: 5")

    # ── Desfazer: este edital não permite ───────────────────────────────────
    put undo_consolidation_admission_application_path(clara), xhr: true
    expect(clara.reload.status).to eq(Admissions::AdmissionApplication::REPROVED)
  end
end
