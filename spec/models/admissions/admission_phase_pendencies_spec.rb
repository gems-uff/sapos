# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Pendências de uma fase (#681): quais usuários do comitê avaliam cada
# candidato, que pendências a fase cria para ele e como o conjunto de
# formulários de fase é montado para a tela, com as permissões de quem olha.
RSpec.describe Admissions::AdmissionPhase, "pendências e formulários", type: :model do
  before(:each) do
    @template = create_admission_template("Inscrição", {
      "area" => Admissions::FormField::STRING,
    })
    @process = create_closed_admission_process(@template, simple_url: "pendencias-spec")
    @member_form = create_admission_template("Parecer", { "parecer" => Admissions::FormField::STRING })
    @shared_form = create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING })
    @candidate_form = create_admission_template("Complemento", { "extra" => Admissions::FormField::STRING })
    @consolidation_form = create_consolidation_template("Consolidação", { "um" => code_field("1") })
    @phase = add_phase(@process, 1, name: "Análise")
    @ia_reviewer = professor_user("ia@ic.uff.br")
    @db_reviewer = professor_user("db@ic.uff.br")
    @general_reviewer = professor_user("geral@ic.uff.br")
  end

  def application_in(area)
    create_application(@process, fields: { "area" => area }, admission_phase: @phase)
  end

  describe "#committee_users_for_candidate" do
    before(:each) do
      add_committee(
        @phase, [@ia_reviewer], name: "IA",
        form_condition: field_condition("area", Admissions::FormCondition::EQUALS, "IA")
      )
      add_committee(
        @phase, [@db_reviewer], name: "BD",
        form_condition: field_condition("area", Admissions::FormCondition::EQUALS, "BD")
      )
      add_committee(@phase, [@general_reviewer, @ia_reviewer], name: "Geral")
    end

    it "reúne, sem repetir, os usuários dos comitês cuja condição o candidato satisfaz" do
      users = @phase.committee_users_for_candidate(application_in("IA"))
      expect(users.keys).to contain_exactly(@ia_reviewer.id, @general_reviewer.id)
      expect(users[@ia_reviewer.id]).to eq(@ia_reviewer)
    end

    it "só devolve o comitê sem condição quando nenhuma condição casa" do
      users = @phase.committee_users_for_candidate(application_in("Redes"))
      expect(users.keys).to contain_exactly(@general_reviewer.id, @ia_reviewer.id)
    end

    it "estoura quando a condição usa campo ausente e should_raise é dado" do
      FactoryBot.create(:form_field, name: "sumido")
      add_committee(
        @phase, [@db_reviewer], name: "Quebrado",
        form_condition: field_condition("sumido", Admissions::FormCondition::NOT_NULL)
      )
      application = application_in("IA")
      expect {
        @phase.committee_users_for_candidate(
          application, should_raise: Admissions::FormCondition::RAISE_COMMITTEE
        )
      }.to raise_error(Exceptions::MissingFieldException, /sumido/)
      # Sem should_raise a condição só não casa.
      expect(@phase.committee_users_for_candidate(application).keys)
        .to contain_exactly(@ia_reviewer.id, @general_reviewer.id)
    end
  end

  describe "#create_pendencies_for_candidate" do
    it "não cria nada numa fase sem formulários e diz que não há comitê" do
      application = application_in("IA")
      expect(@phase.create_pendencies_for_candidate(application)).to be false
      expect(application.pendencies).to be_empty
    end

    it "cria a pendência de candidato quando há formulário de candidato" do
      @phase.update!(candidate_form: @candidate_form)
      application = application_in("IA")
      @phase.create_pendencies_for_candidate(application)

      pendency = application.pendencies.find_by(mode: Admissions::AdmissionPendency::CANDIDATE)
      expect(pendency.status).to eq(Admissions::AdmissionPendency::PENDENT)
      expect(pendency.user_id).to be_nil
    end

    it "marca a pendência de candidato como resolvida quando o formulário já foi preenchido" do
      @phase.update!(candidate_form: @candidate_form)
      application = application_in("IA")
      create_phase_result(application, @phase, Admissions::AdmissionPhaseResult::CANDIDATE)
      @phase.create_pendencies_for_candidate(application)

      expect(application.pendencies.find_by(mode: Admissions::AdmissionPendency::CANDIDATE).status)
        .to eq(Admissions::AdmissionPendency::OK)
    end

    context "com formulário individual de comitê" do
      before(:each) do
        @phase.update!(member_form: @member_form)
      end

      it "cria uma pendência sem usuário quando não há comitê para o candidato" do
        application = application_in("IA")
        expect(@phase.create_pendencies_for_candidate(application)).to be false
        pendencies = application.pendencies.where(mode: Admissions::AdmissionPendency::MEMBER)
        expect(pendencies.pluck(:user_id, :status)).to eq([[nil, Admissions::AdmissionPendency::PENDENT]])
      end

      it "cria uma pendência por membro, resolvida para quem já avaliou" do
        add_committee(@phase, [@ia_reviewer, @db_reviewer])
        application = application_in("IA")
        create_evaluation(application, @phase, @ia_reviewer, fields: { "parecer" => "ok" })

        expect(@phase.create_pendencies_for_candidate(application)).to be true
        statuses = application.pendencies.where(mode: Admissions::AdmissionPendency::MEMBER)
          .pluck(:user_id, :status).to_h
        expect(statuses).to eq({
          @ia_reviewer.id => Admissions::AdmissionPendency::OK,
          @db_reviewer.id => Admissions::AdmissionPendency::PENDENT,
        })
      end

      it "apaga a pendência de quem saiu do comitê" do
        committee = add_committee(@phase, [@ia_reviewer, @db_reviewer])
        application = application_in("IA")
        @phase.create_pendencies_for_candidate(application)
        committee.members.find_by(user: @db_reviewer).destroy
        @phase.reload.create_pendencies_for_candidate(application)

        expect(application.pendencies.where(mode: Admissions::AdmissionPendency::MEMBER).pluck(:user_id))
          .to contain_exactly(@ia_reviewer.id)
      end
    end

    context "com formulário compartilhado" do
      before(:each) do
        @phase.update!(shared_form: @shared_form)
      end

      it "cria uma pendência compartilhada por membro com o mesmo status" do
        add_committee(@phase, [@ia_reviewer, @db_reviewer])
        application = application_in("IA")
        create_phase_result(application, @phase, Admissions::AdmissionPhaseResult::SHARED)
        @phase.create_pendencies_for_candidate(application)

        pendencies = application.pendencies.where(mode: Admissions::AdmissionPendency::SHARED)
        expect(pendencies.pluck(:user_id)).to contain_exactly(@ia_reviewer.id, @db_reviewer.id)
        expect(pendencies.pluck(:status).uniq).to eq([Admissions::AdmissionPendency::OK])
      end

      it "cria uma pendência compartilhada sem usuário quando não há comitê" do
        application = application_in("IA")
        @phase.create_pendencies_for_candidate(application)
        expect(application.pendencies.where(mode: Admissions::AdmissionPendency::SHARED).pluck(:user_id, :status))
          .to eq([[nil, Admissions::AdmissionPendency::PENDENT]])
      end
    end
  end

  describe "#update_pendencies" do
    it "recria as pendências dos candidatos não consolidados da fase, e só deles" do
      @phase.update!(member_form: @member_form)
      add_committee(@phase, [@ia_reviewer])
      open_one = application_in("IA")
      decided = create_application(
        @process, fields: { "area" => "IA" }, admission_phase: @phase,
        status: Admissions::AdmissionApplication::APPROVED
      )
      Admissions::AdmissionPendency.delete_all

      @phase.update_pendencies

      expect(open_one.pendencies.count).to eq(1)
      expect(decided.pendencies.count).to eq(0)
    end

    it "roda ao salvar a fase e ao salvar o comitê" do
      application = application_in("IA")
      @phase.update!(member_form: @member_form)
      expect(application.pendencies.where(mode: Admissions::AdmissionPendency::MEMBER).pluck(:user_id))
        .to eq([nil])

      # Objeto recarregado, como o controller o teria: o @phase em memória
      # guarda o cache de comitês vazio da chamada anterior.
      add_committee(Admissions::AdmissionPhase.find(@phase.id), [@ia_reviewer])
      expect(application.pendencies.reload.where(mode: Admissions::AdmissionPendency::MEMBER).pluck(:user_id))
        .to eq([@ia_reviewer.id])
    end
  end

  describe "#prepare_application_forms" do
    before(:each) do
      @phase.update!(
        shared_form: @shared_form, member_form: @member_form,
        candidate_form: @candidate_form, consolidation_form: @consolidation_form
      )
      add_committee(@phase, [@ia_reviewer, @db_reviewer])
      @application = application_in("IA")
      @phase.create_pendencies_for_candidate(@application)
    end

    def forms_by_mode(result)
      result[:phase_forms].group_by { |form| form[:mode] }
    end

    it "monta um formulário por modo, construindo em memória o que ainda não existe" do
      result = @phase.prepare_application_forms(@application)

      expect(result[:latest_available_phase]).to be true
      by_mode = forms_by_mode(result)
      expect(by_mode.keys).to contain_exactly(:shared, :candidate, :member)
      expect(by_mode[:member].map { |form| form[:user_id] })
        .to contain_exactly(@ia_reviewer.id, @db_reviewer.id)
      expect(by_mode[:member].map { |form| form[:name] })
        .to contain_exactly(@ia_reviewer.name, @db_reviewer.name)
      expect(result[:phase_forms].all? { |form| form[:from_build] }).to be true
      expect(result[:phase_forms].all? { |form| form[:can_edit_form] }).to be true
      # Os campos do template vêm preparados, ainda sem gravar.
      expect(by_mode[:shared][0][:object].filled_form.fields.map(&:form_field_id))
        .to eq(@shared_form.fields.pluck(:id))
      expect(@application.results.reload).to be_empty
    end

    it "não constrói a consolidação enquanto a fase está em andamento" do
      result = @phase.prepare_application_forms(@application)
      expect(forms_by_mode(result)[:consolidation]).to be_nil
    end

    it "mostra a consolidação existente e reaproveita formulários já gravados" do
      shared = create_phase_result(@application, @phase, Admissions::AdmissionPhaseResult::SHARED)
      consolidation = create_phase_result(@application, @phase, Admissions::AdmissionPhaseResult::CONSOLIDATION)
      evaluation = create_evaluation(@application, @phase, @ia_reviewer)

      result = @phase.prepare_application_forms(@application)
      by_mode = forms_by_mode(result)

      expect(by_mode[:shared][0][:object]).to eq(shared)
      expect(by_mode[:shared][0][:from_build]).to be false
      expect(by_mode[:consolidation][0][:object]).to eq(consolidation)
      member = by_mode[:member].find { |form| form[:user_id] == @ia_reviewer.id }
      expect(member[:object]).to eq(evaluation)
      expect(member[:from_build]).to be false
    end

    it "constrói a consolidação depois que a fase foi decidida, sem permitir edição" do
      @application.update!(status: Admissions::AdmissionApplication::APPROVED)
      result = @phase.prepare_application_forms(@application)

      consolidation = forms_by_mode(result)[:consolidation][0]
      expect(consolidation[:from_build]).to be true
      expect(consolidation[:pendency_success]).to be_nil
      expect(result[:phase_forms].none? { |form| form[:can_edit_form] }).to be true
    end

    it "libera a edição de fase já decidida com can_edit_override" do
      @application.update!(status: Admissions::AdmissionApplication::APPROVED)
      result = @phase.prepare_application_forms(@application, can_edit_override: true)
      expect(result[:phase_forms].all? { |form| form[:can_edit_form] }).to be true
    end

    it "marca como fase anterior quando a candidatura já está em outra" do
      later = add_phase(@process, 2, name: "Entrevista")
      @application.update!(admission_phase: later)
      result = @phase.prepare_application_forms(@application)
      expect(result[:latest_available_phase]).to be false
      expect(result[:phase_forms].none? { |form| form[:can_edit_form] }).to be true
    end

    context "com a permissão do candidato" do
      it "esconde o que a fase não deixa o candidato ver e só libera o formulário dele" do
        result = @phase.prepare_application_forms(@application, check_candidate_permission: true)
        expect(forms_by_mode(result).keys).to eq([:candidate])
        expect(result[:phase_forms][0][:can_edit_form]).to be true
      end

      it "mostra o que a fase deixa ver, sem liberar edição" do
        @phase.update!(candidate_can_see_shared: true, candidate_can_see_member: true, candidate_can_see_consolidation: true)
        @application.update!(status: Admissions::AdmissionApplication::APPROVED)
        result = @phase.prepare_application_forms(@application, check_candidate_permission: true)
        by_mode = forms_by_mode(result)
        expect(by_mode.keys).to contain_exactly(:shared, :candidate, :member, :consolidation)
        expect(result[:phase_forms].none? { |form| form[:can_edit_form] }).to be true
      end

      it "deixa o candidato editar o próprio formulário quando a fase permite, mesmo decidida" do
        @phase.update!(candidate_can_edit: true)
        result = @phase.prepare_application_forms(@application, check_candidate_permission: true)
        expect(result[:phase_forms][0][:can_edit_form]).to be true
      end
    end

    context "com a permissão de um membro do comitê" do
      it "mostra só a avaliação do próprio membro, editável, e o candidato bloqueado" do
        result = @phase.prepare_application_forms(@application, committee_permission_user: @ia_reviewer)
        by_mode = forms_by_mode(result)
        expect(by_mode[:member].map { |form| form[:user_id] }).to eq([@ia_reviewer.id])
        expect(by_mode[:member][0][:can_edit_form]).to be true
        expect(by_mode[:candidate][0][:can_edit_form]).to be false
        expect(by_mode[:shared][0][:can_edit_form]).to be true
      end

      it "mostra as avaliações dos outros quando a fase deixa, sem liberar edição" do
        @phase.update!(committee_can_see_other_individual: true)
        result = @phase.prepare_application_forms(@application, committee_permission_user: @ia_reviewer)
        members = forms_by_mode(result)[:member]
        expect(members.map { |form| form[:user_id] }).to contain_exactly(@ia_reviewer.id, @db_reviewer.id)
        other = members.find { |form| form[:user_id] == @db_reviewer.id }
        expect(other[:can_edit_form]).to be false
      end

      it "deixa o comitê editar o formulário do candidato quando a fase permite" do
        @phase.update!(can_edit_candidate: true)
        result = @phase.prepare_application_forms(@application, committee_permission_user: @ia_reviewer)
        expect(forms_by_mode(result)[:candidate][0][:can_edit_form]).to be true
      end

      it "libera tudo com can_edit_override" do
        result = @phase.prepare_application_forms(
          @application, committee_permission_user: @db_reviewer, can_edit_override: true
        )
        expect(result[:phase_forms].all? { |form| form[:can_edit_form] }).to be true
      end
    end
  end

  describe "#initialize_dup" do
    it "duplica comitês da fase e as duas condições" do
      approval = field_condition("area", Admissions::FormCondition::EQUALS, "IA")
      keep = field_condition("area", Admissions::FormCondition::EQUALS, "BD")
      @phase.update!(approval_condition: approval, keep_in_phase_condition: keep)
      add_committee(@phase, [@ia_reviewer])

      copy = @phase.dup

      expect(copy.admission_phase_committees.size).to eq(1)
      expect(copy.admission_phase_committees[0]).not_to eq(@phase.admission_phase_committees[0])
      expect(copy.approval_condition.value).to eq("IA")
      expect(copy.approval_condition).to be_new_record
      expect(copy.keep_in_phase_condition.value).to eq("BD")
    end
  end
end

RSpec.describe Admissions::AdmissionPendency, "escopos", type: :model do
  before(:each) do
    @template = create_admission_template("Inscrição", { "x" => Admissions::FormField::STRING })
    @process = create_closed_admission_process(@template, simple_url: "pendencias-escopos")
    @phase = add_phase(@process, 1)
    @application = create_application(@process, admission_phase: @phase)
    @user = professor_user("escopos@ic.uff.br")
  end

  def pendency(mode, user: nil, status: Admissions::AdmissionPendency::PENDENT)
    FactoryBot.create(
      :admission_pendency, admission_application: @application, admission_phase: @phase,
      mode: mode, user: user, status: status
    )
  end

  it "separa comitê ausente, individual, compartilhada e de candidato" do
    missing = pendency(Admissions::AdmissionPendency::MEMBER)
    member = pendency(Admissions::AdmissionPendency::MEMBER, user: @user)
    shared = pendency(Admissions::AdmissionPendency::SHARED, user: @user)
    candidate = pendency(Admissions::AdmissionPendency::CANDIDATE)
    pendency(Admissions::AdmissionPendency::CANDIDATE, user: @user, status: Admissions::AdmissionPendency::OK)

    expect(Admissions::AdmissionPendency.missing_committee(@phase.id)).to contain_exactly(missing)
    expect(Admissions::AdmissionPendency.member_pendency(@phase.id)).to contain_exactly(member)
    expect(Admissions::AdmissionPendency.shared_pendency(@phase.id)).to contain_exactly(shared)
    expect(Admissions::AdmissionPendency.candidate_pendency(@phase.id)).to contain_exactly(candidate)
    expect(Admissions::AdmissionPendency.pendencies(@phase.id)).to contain_exactly(missing, member, shared, candidate)
    expect(Admissions::AdmissionPendency.pendencies(@phase.id, @user.id)).to contain_exactly(member, shared)
    expect(Admissions::AdmissionPendency.pendencies(@phase.id, @user.id, Admissions::AdmissionPendency::SHARED))
      .to contain_exactly(shared)
  end

  it "status_value traduz preenchido em OK e o resto em pendente" do
    expect(Admissions::AdmissionPendency.status_value(true)).to eq(Admissions::AdmissionPendency::OK)
    expect(Admissions::AdmissionPendency.status_value(nil)).to eq(Admissions::AdmissionPendency::PENDENT)
  end

  it "os escopos da candidatura seguem as pendências da fase" do
    pendency(Admissions::AdmissionPendency::MEMBER)
    expect(Admissions::AdmissionApplication.missing_committee(@phase.id)).to contain_exactly(@application)
    expect(Admissions::AdmissionApplication.member_pendency(@phase.id)).to be_empty
    pendency(Admissions::AdmissionPendency::MEMBER, user: @user)
    expect(Admissions::AdmissionApplication.member_pendency(@phase.id)).to contain_exactly(@application)
    pendency(Admissions::AdmissionPendency::SHARED, user: @user)
    expect(Admissions::AdmissionApplication.shared_pendency(@phase.id)).to contain_exactly(@application)
    pendency(Admissions::AdmissionPendency::CANDIDATE)
    expect(Admissions::AdmissionApplication.candidate_pendency(@phase.id)).to contain_exactly(@application)
  end

  it "pendency_condition devolve consulta vazia sem usuário e a lista de pendências com ele" do
    expect(Admissions::AdmissionApplication.pendency_condition(nil)).to eq(["0 = -1"])
    pendency(Admissions::AdmissionPendency::MEMBER, user: @user)
    matched = Admissions::AdmissionApplication.where(Admissions::AdmissionApplication.pendency_condition(@user))
    expect(matched).to contain_exactly(@application)
  end
end
