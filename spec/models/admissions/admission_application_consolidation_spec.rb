# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Consolidação de fase de uma candidatura (#681): a decisão aprovado, reprovado,
# continua na fase ou erro, a partir das condições da fase e do formulário de
# consolidação; o desfazer dessa decisão; e o estado descritivo que a lista de
# candidaturas mostra a partir das pendências.
RSpec.describe Admissions::AdmissionApplication, "consolidação de fase", type: :model do
  before(:each) do
    @template = create_admission_template(
      "Inscrição", { "nota" => Admissions::FormField::NUMBER }
    )
    @process = create_closed_admission_process(@template, simple_url: "consolidacao-spec")
    @phase = add_phase(
      @process, 1, name: "Análise",
      approval_condition: field_condition("nota", Admissions::FormCondition::GE, "7"),
      keep_in_phase_condition: field_condition("nota", Admissions::FormCondition::GE, "5")
    )
  end

  def application_with_grade(grade, phase: @phase, **attrs)
    create_application(@process, fields: { "nota" => grade }, admission_phase: phase, **attrs)
  end

  describe "#consolidate_phase" do
    it "aprova direto quando não há fase (consolidação da candidatura)" do
      application = application_with_grade("1", phase: nil)
      expect(application.consolidate_phase(nil)).to eq(
        { status: Admissions::AdmissionApplication::APPROVED, status_message: nil }
      )
    end

    it "aprova quando a condição de aprovação é satisfeita" do
      expect(application_with_grade("8").consolidate_phase(@phase)).to eq(
        { status: Admissions::AdmissionApplication::APPROVED, status_message: nil }
      )
    end

    it "mantém na fase quando só a condição de permanência é satisfeita" do
      expect(application_with_grade("6").consolidate_phase(@phase)).to eq({})
    end

    it "reprova quando nenhuma das condições é satisfeita" do
      expect(application_with_grade("4").consolidate_phase(@phase)).to eq(
        { status: Admissions::AdmissionApplication::REPROVED, status_message: nil }
      )
    end

    it "reprova quando não há condição de permanência" do
      @phase.update!(keep_in_phase_condition: nil)
      expect(application_with_grade("6").consolidate_phase(@phase)[:status]).to eq(
        Admissions::AdmissionApplication::REPROVED
      )
    end

    it "devolve erro quando a condição usa campo que a candidatura não tem" do
      FactoryBot.create(:form_field, name: "inexistente")
      @phase.update!(
        approval_condition: field_condition("inexistente", Admissions::FormCondition::NOT_NULL)
      )
      result = application_with_grade("8").consolidate_phase(@phase)

      expect(result[:status]).to eq(Admissions::AdmissionApplication::ERROR)
      expect(result[:status_message]).to be_a(Exceptions::MissingFieldException)
      expect(result[:status_message].message).to include("inexistente")
      expect(result[:status_message].message).to include(Admissions::FormCondition::RAISE_PHASE)
    end

    context "com formulário de consolidação" do
      before(:each) do
        @member_form = create_admission_template(
          "Parecer", { "parecer" => Admissions::FormField::NUMBER }
        )
        @consolidation = create_consolidation_template("Consolidação", {
          "dobro" => code_field("{{ fields.nota | times: 2 }}"),
          "pareceres" => code_field("{{ committees | size }}"),
          "media" => code_field('{{ committees | avg: "parecer" }}'),
        })
        @phase.update!(
          member_form: @member_form,
          consolidation_form: @consolidation,
          approval_condition: field_condition("dobro", Admissions::FormCondition::GE, "16")
        )
        @application = application_with_grade("8")
        @reviewer = professor_user("reviewer-consolidacao@ic.uff.br")
        @absent = professor_user("absent-consolidacao@ic.uff.br")
      end

      it "calcula os campos de código a partir dos campos e dos pareceres preenchidos" do
        create_evaluation(@application, @phase, @reviewer, fields: { "parecer" => "9" })
        # Parecer não preenchido não entra na lista de comitês.
        Admissions::AdmissionPhaseEvaluation.create!(
          admission_phase: @phase, admission_application: @application, user: @absent
        )

        result = @application.consolidate_phase(@phase)

        expect(result[:status]).to eq(Admissions::AdmissionApplication::APPROVED)
        consolidated = @application.results.find_by(
          admission_phase: @phase, mode: Admissions::AdmissionPhaseResult::CONSOLIDATION
        )
        expect(consolidated.filled_form.is_filled).to be true
        values = consolidated.filled_form.to_fields_hash.transform_values(&:value)
        expect(values).to eq({ "dobro" => "16", "pareceres" => "1", "media" => "9.0" })
      end

      it "decide pela condição sobre o campo calculado" do
        # nota 2: dobro 4 não aprova, e 2 < 5 tampouco mantém na fase.
        @application.filled_form.fields.first.update!(value: "2")
        expect(@application.consolidate_phase(@phase)[:status]).to eq(
          Admissions::AdmissionApplication::REPROVED
        )
      end

      it "reaproveita o resultado de consolidação existente em vez de criar outro" do
        @application.consolidate_phase(@phase)
        expect { @application.consolidate_phase(@phase) }.not_to change {
          Admissions::AdmissionPhaseResult.count
        }
      end

      it "devolve erro e ainda grava o resultado quando a consolidação estoura" do
        FactoryBot.create(:form_field, name: "condicao_ausente")
        @consolidation.fields.find_by(name: "dobro").update!(
          configuration: JSON.dump(
            code_field(
              "1",
              condition: { "mode" => Admissions::FormCondition::CONDITION,
                           "field" => "condicao_ausente",
                           "condition" => Admissions::FormCondition::NOT_NULL }
            )[:configuration]
          )
        )

        result = @application.consolidate_phase(@phase)

        expect(result[:status]).to eq(Admissions::AdmissionApplication::ERROR)
        expect(result[:status_message]).to be_a(Exceptions::MissingFieldException)
        consolidated = @application.results.find_by(
          admission_phase: @phase, mode: Admissions::AdmissionPhaseResult::CONSOLIDATION
        )
        expect(consolidated).to be_present
        expect(consolidated.filled_form.is_filled).to be false
      end
    end
  end

  describe "#consolidate_phase!" do
    it "grava o status decidido e o devolve" do
      application = application_with_grade("8")
      expect(application.consolidate_phase!(@phase)).to eq(Admissions::AdmissionApplication::APPROVED)
      expect(application.reload.status).to eq(Admissions::AdmissionApplication::APPROVED)
    end

    it "não muda nada quando a candidatura continua na fase" do
      application = application_with_grade("6")
      expect(application.consolidate_phase!(@phase)).to be_nil
      expect(application.reload.status).to be_nil
    end

    it "grava a mensagem do erro como texto" do
      FactoryBot.create(:form_field, name: "outro_inexistente")
      @phase.update!(
        approval_condition: field_condition("outro_inexistente", Admissions::FormCondition::NOT_NULL)
      )
      application = application_with_grade("8")
      expect(application.consolidate_phase!(@phase)).to eq(Admissions::AdmissionApplication::ERROR)
      expect(application.reload.status_message).to include("outro_inexistente")
    end
  end

  describe "#undo_consolidation" do
    before(:each) do
      @phase2 = add_phase(@process, 2, name: "Entrevista")
    end

    it "volta a candidatura aprovada para a mesma fase, sem status" do
      application = application_with_grade("8")
      application.update!(status: Admissions::AdmissionApplication::APPROVED)

      expect(application.undo_consolidation).to eq("Análise")
      application.reload
      expect(application.admission_phase).to eq(@phase)
      expect(application.status).to be_nil
    end

    it "volta a candidatura em andamento para a fase anterior e apaga o que a fase atual deixou" do
      application = application_with_grade("8", phase: @phase2)
      @phase.update!(
        consolidation_form: create_consolidation_template("Consolidação 1", { "um" => code_field("1") }),
        shared_form: create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING })
      )
      create_phase_result(application, @phase, Admissions::AdmissionPhaseResult::CONSOLIDATION)
      # Fase 1 também tem um resultado que não é de consolidação e precisa ficar.
      shared = create_phase_result(application, @phase, Admissions::AdmissionPhaseResult::SHARED)
      pendency = FactoryBot.create(
        :admission_pendency, admission_application: application, admission_phase: @phase2
      )

      expect(application.undo_consolidation).to eq("Análise")
      application.reload
      expect(application.admission_phase).to eq(@phase)
      expect(application.status).to be_nil
      expect(Admissions::AdmissionPendency.exists?(pendency.id)).to be false
      expect(application.results.where(mode: Admissions::AdmissionPhaseResult::CONSOLIDATION)).to be_empty
      expect(Admissions::AdmissionPhaseResult.exists?(shared.id)).to be true
    end

    it "volta da primeira fase para a candidatura" do
      application = application_with_grade("8")
      expect(application.undo_consolidation).to eq("Candidatura")
      expect(application.reload.admission_phase).to be_nil
    end

    it "repõe as pendências da fase para onde voltou" do
      @phase.update!(member_form: create_admission_template("Parecer 2", { "p" => Admissions::FormField::STRING }))
      add_committee(@phase, [professor_user("undo-member@ic.uff.br")])
      application = application_with_grade("8", phase: @phase2)
      Admissions::AdmissionPendency.where(admission_application: application).delete_all

      application.undo_consolidation

      expect(application.pendencies.where(
        admission_phase: @phase, mode: Admissions::AdmissionPendency::MEMBER
      )).to exist
    end
  end

  describe "#descriptive_status" do
    it "mostra o status quando já decidido" do
      application = application_with_grade("8", status: Admissions::AdmissionApplication::APPROVED)
      expect(application.descriptive_status).to eq(Admissions::AdmissionApplication::APPROVED)
    end

    it "acrescenta a mensagem ao status" do
      application = application_with_grade(
        "8", status: Admissions::AdmissionApplication::ERROR, status_message: "campo ausente"
      )
      expect(application.descriptive_status).to eq("#{Admissions::AdmissionApplication::ERROR}: campo ausente")
    end

    it "lista as pendências compartilhada e de candidato" do
      application = application_with_grade("8")
      [Admissions::AdmissionPendency::SHARED, Admissions::AdmissionPendency::CANDIDATE].each do |mode|
        FactoryBot.create(
          :admission_pendency, admission_application: application,
          admission_phase: @phase, mode: mode
        )
      end
      expect(application.descriptive_status).to eq(
        "Pendente: #{Admissions::AdmissionPendency::SHARED}, #{Admissions::AdmissionPendency::CANDIDATE}"
      )
    end

    it "avisa quando não há comitê válido" do
      application = application_with_grade("8")
      FactoryBot.create(
        :admission_pendency, admission_application: application, admission_phase: @phase,
        mode: Admissions::AdmissionPendency::MEMBER, user: nil
      )
      expect(application.descriptive_status).to eq("Pendente: Sem comitê válido")
    end

    it "nomeia os membros do comitê que ainda não avaliaram" do
      application = application_with_grade("8")
      pending = professor_user("pendente@ic.uff.br")
      done = professor_user("avaliou@ic.uff.br")
      FactoryBot.create(
        :admission_pendency, admission_application: application, admission_phase: @phase,
        mode: Admissions::AdmissionPendency::MEMBER, user: pending
      )
      FactoryBot.create(
        :admission_pendency, admission_application: application, admission_phase: @phase,
        mode: Admissions::AdmissionPendency::MEMBER, user: done,
        status: Admissions::AdmissionPendency::OK
      )
      expect(application.descriptive_status).to eq("Pendente: #{pending.name}")
    end

    it "é pendente enquanto a inscrição não foi enviada" do
      application = create_application(@process, filled: false)
      expect(application.descriptive_status).to eq("Pendente")
    end

    it "está pronta para consolidação sem pendência alguma" do
      expect(application_with_grade("8").descriptive_status).to eq("Pronto para consolidação")
    end
  end

  describe "#can_edit_itself" do
    it "pode enquanto está na candidatura" do
      expect(application_with_grade("8", phase: nil).can_edit_itself).to be true
    end

    it "não pode quando a fase não deixa o candidato editar" do
      expect(application_with_grade("8").can_edit_itself).to be false
    end

    it "pode na fase que deixa, até a decisão" do
      @phase.update!(candidate_can_edit: true)
      application = application_with_grade("8")
      expect(application.can_edit_itself).to be true
      application.update!(status: Admissions::AdmissionApplication::REPROVED)
      expect(application.can_edit_itself).to be false
    end
  end

  describe "#candidate_can_edit" do
    it "não devolve ação para inscrição não enviada em processo fechado" do
      expect(create_application(@process, filled: false).candidate_can_edit).to be_nil
    end

    it "devolve :new para inscrição não enviada em processo aberto" do
      @process.update!(end_date: Date.today + 5.days, edit_date: Date.today + 10.days)
      expect(create_application(@process, filled: false).candidate_can_edit).to eq([:new, {}])
    end

    it "devolve :edit para inscrição enviada em processo ainda editável" do
      @process.update!(end_date: Date.today - 1.day, edit_date: Date.today + 10.days)
      expect(application_with_grade("8", phase: nil).candidate_can_edit).to eq([:edit, {}])
    end

    it "não devolve ação para inscrição enviada em processo já fechado para edição" do
      expect(application_with_grade("8", phase: nil).candidate_can_edit).to be_nil
    end

    context "na fase com formulário de candidato" do
      before(:each) do
        @phase.update!(
          candidate_form: create_admission_template("Complemento", { "extra" => Admissions::FormField::STRING })
        )
        @application = application_with_grade("8")
      end

      it "devolve :new_phase enquanto o candidato não preencheu" do
        expect(@application.candidate_can_edit).to eq([:new_phase, phase: "Análise"])
      end

      it "devolve :edit_phase depois de preenchido" do
        create_phase_result(@application, @phase, Admissions::AdmissionPhaseResult::CANDIDATE)
        expect(@application.candidate_can_edit).to eq([:edit_phase, phase: "Análise"])
      end
    end
  end

  describe "escopos de consolidação" do
    before(:each) do
      @ready = application_with_grade("8", phase: nil)
      @unfilled = create_application(@process, filled: false)
      @done = application_with_grade("8", phase: nil, status: Admissions::AdmissionApplication::APPROVED)
      @errored = application_with_grade("8", phase: nil, status: Admissions::AdmissionApplication::ERROR)
    end

    it "non_consolidated inclui quem não tem status ou está em erro" do
      expect(Admissions::AdmissionApplication.non_consolidated.where(admission_process: @process))
        .to contain_exactly(@ready, @unfilled, @errored)
    end

    it "ready_for_consolidation sem fase exige inscrição enviada" do
      expect(Admissions::AdmissionApplication.ready_for_consolidation(nil).where(admission_process: @process))
        .to contain_exactly(@ready, @errored)
    end

    it "fill_pendency lista quem ainda não enviou" do
      expect(Admissions::AdmissionApplication.fill_pendency(nil).where(admission_process: @process))
        .to contain_exactly(@unfilled)
    end

    it "ready_for_consolidation com fase exclui quem tem pendência na fase" do
      in_phase = application_with_grade("8")
      blocked = application_with_grade("8")
      FactoryBot.create(
        :admission_pendency, admission_application: blocked, admission_phase: @phase
      )
      # O escopo não filtra pela fase: quem o usa restringe antes. Aqui a
      # restrição vem junto, como no controller.
      expect(Admissions::AdmissionApplication.ready_for_consolidation(@phase.id).where(admission_phase: @phase))
        .to contain_exactly(in_phase)
    end

    it "phase_condition filtra pela fase" do
      in_phase = application_with_grade("8")
      expect(Admissions::AdmissionApplication.where(Admissions::AdmissionApplication.phase_condition(@phase.id)))
        .to contain_exactly(in_phase)
    end
  end

  describe "campos e condições" do
    it "fields_hash reúne campos sombra, inscrição, resultados de fase e rankings" do
      @phase.update!(shared_form: create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING }))
      application = application_with_grade("8")
      create_phase_result(application, @phase, Admissions::AdmissionPhaseResult::SHARED, fields: { "obs" => "ok" })
      ranking = FactoryBot.create(:ranking_config, name: "Geral", default_column: "nota")
      FactoryBot.create(:admission_process_ranking, admission_process: @process, ranking_config: ranking, order: 1)
      result = Admissions::AdmissionRankingResult.create!(admission_application: application, ranking_config: ranking)
      result.filled_position.update!(value: "3")
      result.filled_form.update!(is_filled: true)

      fields = application.fields_hash

      expect(fields["name"].value).to eq("Ana")
      expect(fields[Admissions::AdmissionApplication.record_i18n_attr("name")].value).to eq("Ana")
      expect(fields["nota"].value).to eq("8")
      expect(fields["obs"].value).to eq("ok")
      expect(fields["#{Admissions::RankingConfig::POSITION}/Geral"].value).to eq("3")
    end

    it "satisfies_condition procura o campo no resultado de fase, na inscrição e nos atributos" do
      @phase.update!(shared_form: create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING }))
      application = application_with_grade("8")
      create_phase_result(application, @phase, Admissions::AdmissionPhaseResult::SHARED, fields: { "obs" => "aprovar" })

      expect(application.satisfies_condition(field_condition("obs", Admissions::FormCondition::EQUALS, "aprovar"))).to be true
      expect(application.satisfies_condition(field_condition("nota", Admissions::FormCondition::EQUALS, "8"))).to be true
      expect(application.satisfies_condition(field_condition("name", Admissions::FormCondition::STARTS_WITH, "An"))).to be true
      expect(application.satisfies_condition(field_condition("name", Admissions::FormCondition::STARTS_WITH, "Zé"))).to be false
    end

    it "attribute_as_field aceita o rótulo traduzido e ignora atributo que não é sombra" do
      application = application_with_grade("8")
      label = Admissions::AdmissionApplication.record_i18n_attr("email")
      expect(application.attribute_as_field(label).value).to eq(application.email)
      expect(application.attribute_as_field("admission_process_id")).to be_nil
    end
  end

  describe "cartas de recomendação" do
    before(:each) do
      @letters = create_admission_template(
        "Carta", { "texto" => Admissions::FormField::TEXT },
        template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
      )
      @process.update!(letter_template: @letters, min_letters: 2, max_letters: 3)
    end

    it "prepare_missing_letters cria só o que falta para o mínimo" do
      application = create_application(@process, filled: false)
      application.letter_requests.create!(name: "Prof. A", email: "a@example.com")
      application.prepare_missing_letters
      expect(application.letter_requests.size).to eq(2)
      expect(application.letter_requests.count { |letter| letter.new_record? }).to eq(1)
    end

    it "prepare_missing_letters não cria nada quando o processo não pede cartas" do
      @process.update!(min_letters: nil, max_letters: nil)
      application = create_application(@process, filled: false)
      application.prepare_missing_letters
      expect(application.letter_requests).to be_empty
    end

    it "missing_letters? compara as cartas recebidas com o mínimo" do
      application = create_application(@process, filled: false)
      first = application.letter_requests.create!(name: "Prof. A", email: "a@example.com")
      application.letter_requests.create!(name: "Prof. B", email: "b@example.com")
      expect(application.missing_letters?).to be true
      first.filled_form.update!(is_filled: true)
      application.letter_requests.reload.second.filled_form.update!(is_filled: true)
      expect(application.reload.missing_letters?).to be false
    end

    it "requested_letters e filled_letters contam pedidos e cartas recebidas" do
      application = create_application(@process, filled: false)
      first = application.letter_requests.create!(name: "Prof. A", email: "a@example.com")
      application.letter_requests.create!(name: "Prof. B", email: "b@example.com")
      first.filled_form.update!(is_filled: true)
      expect(application.requested_letters).to eq(2)
      expect(application.filled_letters).to eq(1)
    end
  end

  describe "aluno correspondente" do
    before(:each) do
      @template_cpf = create_admission_template("Inscrição CPF", {
        "cpf" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "cpf" } },
      })
      @process_cpf = create_closed_admission_process(@template_cpf, simple_url: "cpf-spec")
    end

    it "students_by_cpf ignora pontuação do CPF" do
      student = FactoryBot.create(:student, cpf: "123.456.789-00")
      application = create_application(@process_cpf, fields: { "cpf" => "12345678900" })
      expect(application.students_by_cpf).to contain_exactly(student)
    end

    it "students_by_cpf devolve vazio sem campo de CPF" do
      application = create_application(@process_cpf)
      expect(application.students_by_cpf).to be_empty
    end

    it "students separa quem casa por CPF e e-mail, só CPF ou só e-mail" do
      both = FactoryBot.create(:student, cpf: "111.111.111-11", email: "ana@example.com")
      by_cpf = FactoryBot.create(:student, cpf: "222.222.222-22", email: "outra@example.com")
      by_email = FactoryBot.create(:student, cpf: "333.333.333-33", email: "ANA@example.com ")
      FactoryBot.create(:student, cpf: "444.444.444-44", email: "ninguem@example.com")
      application = create_application(@process_cpf, email: "ana@example.com", fields: { "cpf" => "111.111.111-11" })

      expect(application.students).to eq({ cpf_and_email: [both], email: [by_email] })

      application.filled_form.fields.first.update!(value: "222.222.222-22")
      expect(application.reload.students).to eq({ cpf: [by_cpf], email: [both, by_email] })
    end
  end

  describe "#update_enrollment com campo de número de matrícula" do
    before(:each) do
      @template_number = create_admission_template("Inscrição Matrícula", {
        "matricula" => Admissions::FormField::STRING,
      })
      @process_number = create_closed_admission_process(
        @template_number, simple_url: "matricula-spec", enrollment_number_field: "matricula"
      )
    end

    it "copia o número do campo indicado no edital" do
      application = create_application(@process_number, fields: { "matricula" => "M2026001" })
      enrollment = Enrollment.new
      application.update_enrollment(enrollment)
      expect(enrollment.enrollment_number).to eq("M2026001")
    end

    it "estoura quando a candidatura não tem o campo do edital" do
      application = create_application(@process_number)
      expect { application.update_enrollment(Enrollment.new) }.to raise_error(
        Exceptions::MissingFieldException, /matricula/
      )
    end
  end
end
