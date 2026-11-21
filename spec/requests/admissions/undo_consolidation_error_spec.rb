# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# "Desfazer última consolidação" numa candidatura com Erro deveria só limpar o
# erro da fase atual, que é a consolidação que falhou.
RSpec.describe "Desfazer consolidação de candidatura com Erro", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "undo_error_admin@ic.uff.br")
    template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
    @process = create_closed_admission_process(template, simple_url: "undo-error")
    @phase1 = add_phase(@process, 1, name: "Análise",
      approval_condition: field_condition("nota", Admissions::FormCondition::GE, "7"))
    FactoryBot.create(:form_field, name: "sumido")
    @phase2 = add_phase(@process, 2, name: "Entrevista",
      approval_condition: field_condition("sumido", Admissions::FormCondition::NOT_NULL))
    @phase3 = add_phase(@process, 3, name: "Final")
    @application = create_application(@process, fields: { "nota" => "8" }, admission_phase: @phase1)
    [@phase1, @phase2].each do |phase|
      post consolidate_phase_admission_process_path(@process), params: { consolidate_phase_id: phase.id }
    end
  end

  def undo
    put undo_consolidation_admission_application_path(@application), xhr: true
    @application.reload
  end

  it "chega à fase 2 com Erro" do
    @application.reload
    expect(@application.admission_phase).to eq(@phase2)
    expect(@application.status).to eq(Admissions::AdmissionApplication::ERROR)
  end

  it "volta à fase anterior a candidatura sem status" do
    @application.update!(status: nil, status_message: nil)
    expect(undo.admission_phase).to eq(@phase1)
  end

  it "mantém a fase da candidatura aprovada e limpa o status" do
    @application.update!(status: Admissions::AdmissionApplication::APPROVED, status_message: nil)
    expect(undo.admission_phase).to eq(@phase2)
    expect(@application.status).to be_nil
  end

  it "mantém a fase da candidatura com Erro e limpa o erro", pending: "issue #760" do
    expect(undo.admission_phase).to eq(@phase2)
    expect(@application.status).to be_nil
    expect(@application.status_message).to be_nil
  end
end
