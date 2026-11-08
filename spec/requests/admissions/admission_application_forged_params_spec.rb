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
end
