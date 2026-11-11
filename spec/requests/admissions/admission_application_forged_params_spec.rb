# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Na edicao da candidatura, o membro de comissao so ve editavel o proprio
# parecer. O que a tela nao oferece tem de ser recusado tambem quando chega nos
# parametros, e a permissao de edicao total (override) e do papel, nao de um
# campo do formulario. Cada exemplo manda, na mesma requisicao, o parecer do
# proprio membro -- que tem de ser gravado, senao a recusa do resto nao prova
# nada -- e uma alteracao que a tela nao oferece.
RSpec.describe "Admissions::AdmissionApplications com parametros fora do formulario", type: :request do
  before(:each) do
    @template = create_admission_template("Inscricao", { "nota" => Admissions::FormField::NUMBER })
    @process = create_closed_admission_process(@template, simple_url: "forjado-#{SecureRandom.hex(4)}")
    @member_form = create_admission_template("Parecer", { "Parecer" => Admissions::FormField::NUMBER })
    @phase = add_phase(@process, 1, member_form: @member_form)
    @reviewer = professor_user("forjado-revisor-#{SecureRandom.hex(3)}@ic.uff.br")
    @other = professor_user("forjado-outro-#{SecureRandom.hex(3)}@ic.uff.br")
    add_committee(@phase, [@reviewer, @other])
    @application = create_application(@process, fields: { "nota" => "8" }, admission_phase: @phase)
    @phase.create_pendencies_for_candidate(@application)
    @other_evaluation = create_evaluation(@application, @phase, @other, fields: { "Parecer" => "7" })
    sign_in @reviewer
  end

  def field_of(filled_form, name)
    filled_form.fields.joins(:form_field).find_by!(form_field: { name: name })
  end

  def own_evaluation_entry
    {
      user_id: @reviewer.id, admission_phase_id: @phase.id,
      filled_form_attributes: {
        enable_submission: "1", form_template_id: @member_form.id,
        fields_attributes: { "0" => {
          form_field_id: @member_form.fields.first.id, value: "9"
        } }
      }
    }
  end

  def other_evaluation_entry
    {
      id: @other_evaluation.id,
      filled_form_attributes: {
        id: @other_evaluation.filled_form.id,
        fields_attributes: { "0" => {
          id: field_of(@other_evaluation.filled_form, "Parecer").id, value: "1"
        } }
      }
    }
  end

  def own_evaluation_value
    evaluation = @application.evaluations.find_by!(user: @reviewer)
    field_of(evaluation.filled_form, "Parecer").value
  end

  it "nao altera o parecer de outro membro" do
    # can_edit_override vazio e o que o formulario manda a quem nao tem o papel.
    put admission_application_path(@application), xhr: true, params: {
      can_edit_override: "",
      record: {
        evaluations_attributes: { "0" => own_evaluation_entry, "1" => other_evaluation_entry }
      }
    }

    expect(own_evaluation_value).to eq "9"
    expect(field_of(@other_evaluation.filled_form, "Parecer").value).to eq "7"
  end

  it "nao concede edicao total a quem manda can_edit_override sem ter o papel" do
    put admission_application_path(@application), xhr: true, params: {
      can_edit_override: "1",
      record: {
        evaluations_attributes: { "0" => own_evaluation_entry, "1" => other_evaluation_entry }
      }
    }

    expect(own_evaluation_value).to eq "9"
    expect(field_of(@other_evaluation.filled_form, "Parecer").value).to eq "7"
  end

  it "nao altera o formulario do candidato" do
    filled_form = @application.filled_form
    put admission_application_path(@application), xhr: true, params: { record: {
      filled_form_attributes: {
        id: filled_form.id, enable_submission: "1",
        fields_attributes: { "0" => { id: field_of(filled_form, "nota").id, value: "10" } }
      },
      evaluations_attributes: { "0" => own_evaluation_entry }
    } }

    expect(own_evaluation_value).to eq "9"
    expect(field_of(filled_form, "nota").value).to eq "8"
  end

  # O nome e o e-mail fazem parte do formulario do candidato: a tela so os
  # oferece a quem pode edita-lo.
  it "nao altera o nome nem o e-mail do candidato" do
    nome, email = @application.name, @application.email

    put admission_application_path(@application), xhr: true, params: { record: {
      name: "Nome Trocado", email: "trocado@example.com",
      evaluations_attributes: { "0" => own_evaluation_entry }
    } }

    expect(own_evaluation_value).to eq "9"
    expect(@application.reload.name).to eq(nome)
    expect(@application.email).to eq(email)
  end

  # Controle: quem tem a edicao total altera o nome e o e-mail pela mesma tela.
  it "altera o nome e o e-mail quando quem edita tem a edicao total" do
    sign_out @reviewer
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "forjado-admin@ic.uff.br", "Admin")

    put admission_application_path(@application), xhr: true, params: {
      can_edit_override: "1", record: { name: "Nome Corrigido", email: "corrigido@example.com" }
    }

    expect(@application.reload.name).to eq("Nome Corrigido")
    expect(@application.email).to eq("corrigido@example.com")
  end

  # O código acompanha o endereço também quando quem corrige o e-mail é a
  # equipe: quem recebeu o código no endereço antigo deixa de abrir a
  # inscrição. O identificador fica, porque é por ele que a inscrição já foi
  # citada.
  it "troca o codigo, e mantem o identificador, quando a equipe corrige o e-mail" do
    codigo = @application.token
    sign_out @reviewer
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "forjado-admin@ic.uff.br", "Admin")

    put admission_application_path(@application), xhr: true, params: {
      can_edit_override: "1", record: { email: "corrigido@example.com" }
    }

    expect(@application.reload.email).to eq("corrigido@example.com")
    expect(@application.token).not_to eq(codigo)
    expect(@application.identifier).to eq(codigo[0, 6])
  end

  # A fase pode deixar o comitê editar o formulário do candidato. O e-mail fica
  # de fora: é para ele que a recuperação manda o código.
  context "em fase que deixa o comite editar o candidato" do
    before(:each) do
      @phase.update!(can_edit_candidate: true)
      allow(Notifier).to receive(:send_emails)
    end

    it "nao deixa o membro trocar o e-mail da candidatura" do
      email, codigo = @application.email, @application.token

      put admission_application_path(@application), xhr: true, params: { record: {
        name: "Nome Corrigido Pelo Comite", email: "membro@example.com",
        evaluations_attributes: { "0" => own_evaluation_entry }
      } }

      expect(own_evaluation_value).to eq "9"
      expect(@application.reload.email).to eq(email)
      expect(@application.token).to eq(codigo)
    end

    # Controle: o que a fase libera ao comitê segue liberado.
    it "deixa o membro corrigir o nome" do
      put admission_application_path(@application), xhr: true, params: { record: {
        name: "Nome Corrigido Pelo Comite", evaluations_attributes: { "0" => own_evaluation_entry }
      } }

      expect(@application.reload.name).to eq("Nome Corrigido Pelo Comite")
    end
  end
end
