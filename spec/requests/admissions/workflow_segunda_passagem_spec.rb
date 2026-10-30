# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Segunda passagem do ranking e lista de bolsas encadeada, pela rota de
# consolidação (#708). Mesmo processo 1 da fixture do fluxo de avaliação
# compartilhada, agora com candidatos bastantes para esgotar a ampla
# concorrência: o grupo Geral tem 40 vagas (30 de ampla e 10 de cota racial no
# passo 1) e o que a cota racial não usa volta para a ampla no passo 2, com o
# seletor gravado como "Ampla concorrência/2". O ranking de Bolsas lê a posição
# gravada pelo de Vagas, em qualquer passagem, e mistura os alunos atuais pela
# nota.
RSpec.describe "Fluxo do processo seletivo: segunda passagem e bolsas", type: :request do
  before(:each) do
    @admin = create_confirmed_user([FactoryBot.create(:role_administrador)], "workflow-2a-admin@example.com")
    @workflow = AdmissionsWorkflowLoader.load(process_id: 1)
    @process = @workflow.process
    @homologacao, @avaliacao = @workflow.phase_links.map(&:admission_phase)
    @vagas, @bolsas = @workflow.ranking_links
    @secretary = @workflow.committee_users[1].first
    @evaluator = @workflow.committee_users[2].first
    @candidates = []
    allow(Notifier).to receive(:send_emails)
  end

  # Notas distintas e decrescentes na ordem de declaração (9,95, 9,90…), para
  # que nenhum desempate entre em jogo; `nota: nil` deixa sem avaliação.
  def candidate(name, bolsa: "Não", cota: nil, nota: 10 - 0.05 * (@candidates.size + 1))
    @candidates << { name: name, bolsa: bolsa, cota: cota, nota: nota }
  end

  def run_process
    @candidates.each_with_index do |c, i|
      c[:application] = apply_as_candidate(@process, name: c[:name], email: "segunda-passagem-#{i}@example.com",
        values: { "Solicita bolsa?" => c[:bolsa] })
    end
    sign_in @admin
    consolidate_phase_as_staff(@process, nil)
    sign_out @admin

    sign_in @secretary
    @candidates.each do |c|
      values = { "Homologação" => "Deferida" }
      values[c[:cota]] = "1" if c[:cota]
      submit_phase_form(c[:application], @homologacao, @homologacao.shared_form, values,
        mode: Admissions::AdmissionPhaseResult::SHARED)
    end
    sign_out @secretary
    sign_in @admin
    consolidate_phase_as_staff(@process, @homologacao)
    sign_out @admin

    sign_in @evaluator
    @candidates.select { |c| c[:nota] }.each do |c|
      grade = format("%.2f", c[:nota])
      submit_phase_form(c[:application], @avaliacao, @avaliacao.shared_form,
        { "Nota de formação" => grade, "Nota de produção" => grade, "Nota de experiência" => grade },
        mode: Admissions::AdmissionPhaseResult::SHARED)
    end
    sign_out @evaluator

    # Quem ficou sem avaliação é reprovado pela pendência e chega à geração
    # dos rankings sem nota final.
    @process.update!(end_date: Date.today - 1)
    sign_in @admin
    consolidate_phase_as_staff(@process, @avaliacao, shared_pendency: "reprove")
    sign_out @admin
  end

  # Nome → [posição, seletor] de quem tem posição no ranking, na ordem das posições.
  def ranked(link)
    @candidates.filter_map do |c|
      (seat = position_and_machine(link, c[:application])) && [c[:name], seat]
    end.sort_by { |_, (position, _)| position }.to_h
  end

  it "esgota a ampla, devolve a sobra da cota racial no passo 2 e ordena a lista de bolsas por nota" do
    novo, aluno = "Sim, ainda não sou aluno", "Sim, já sou aluno"
    (1..10).each { |i| candidate(format("Ampla %02d", i), bolsa: i == 1 ? novo : "Não") }
    candidate("Aluno atual", bolsa: aluno)
    (11..30).each { |i| candidate(format("Ampla %02d", i)) }
    candidate("Cotista 1", bolsa: novo, cota: "Optante por cota racial")
    candidate("Repescado 1", bolsa: novo)
    candidate("Cotista 2", bolsa: novo, cota: "Optante por cota racial")
    candidate("PcD", cota: "PcD")
    (2..8).each { |i| candidate("Repescado #{i}") }
    candidate("Sem posição", bolsa: novo)
    candidate("Aluno abaixo do corte", bolsa: aluno, nota: 5.5)
    candidate("Eliminado", bolsa: novo, nota: 5)
    candidate("Aluno sem nota", bolsa: aluno, nota: nil)
    run_process

    # Passo 1: a ampla, as duas cotas raciais e a PcD; passo 2, depois de
    # todo o passo 1: o que sobrou do grupo Geral (40 - 30 - 2) volta para a
    # ampla. Fora: o aluno atual, que não concorre a vaga, o nono sem cota e os
    # que não chegaram a 6,0.
    expect(ranked(@vagas)).to eq(
      (1..30).to_h { |i| [format("Ampla %02d", i), [i, "Ampla concorrência"]] }
        .merge("Cotista 1" => [31, "Cota racial"], "Cotista 2" => [32, "Cota racial"], "PcD" => [33, "Cota PcD"])
        .merge((1..8).to_h { |i| ["Repescado #{i}", [33 + i, "Ampla concorrência/2"]] })
    )

    # Bolsas: quem tem posição em qualquer passagem e pediu como novo, mais os
    # alunos atuais com nota, pela nota. O repescado fica à frente do cotista
    # de nota menor; o aluno atual abaixo do corte entra, no fim. Fora: o novo
    # sem posição, o eliminado e o aluno atual sem nota, que sem a exigência de
    # nota final na pré-condição abortaria a geração.
    expect(ranked(@bolsas)).to eq(
      "Ampla 01" => [1, "Bolsa"], "Aluno atual" => [2, "Bolsa"], "Cotista 1" => [3, "Bolsa"],
      "Repescado 1" => [4, "Bolsa"], "Cotista 2" => [5, "Bolsa"], "Aluno abaixo do corte" => [6, "Bolsa"]
    )
  end
end
