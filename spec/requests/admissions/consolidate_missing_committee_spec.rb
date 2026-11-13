# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A passagem de fase acusa "Comitê incompleto" sempre que nenhum comitê alcança
# o candidato, inclusive quando a fase seguinte não tem formulário que um
# comitê preencha.
RSpec.describe "Aviso de comitê incompleto na consolidação", type: :request do
  I18N_MISSING = "active_scaffold.admissions/admission_process.consolidate_phase.missing_committee"

  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "missing_committee_admin@ic.uff.br")
    template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
    @process = create_closed_admission_process(template, simple_url: "missing-committee")
    @phase1 = add_phase(@process, 1, name: "Análise",
      approval_condition: field_condition("nota", Admissions::FormCondition::GE, "7"))
    @phase2 = add_phase(@process, 2, name: "Entrevista")
    create_application(@process, fields: { "nota" => "8" }, admission_phase: @phase1)
  end

  def consolidate
    post consolidate_phase_admission_process_path(@process), params: { consolidate_phase_id: @phase1.id }
    flash[:info]
  end

  it "acusa quando a fase seguinte tem formulário de membro e nenhum comitê" do
    @phase2.update!(member_form: create_admission_template("Parecer", { "p" => Admissions::FormField::STRING }))
    expect(consolidate).to include(I18n.t(I18N_MISSING, count: 1))
  end

  it "não acusa quando a fase seguinte tem comitê" do
    add_committee(@phase2, [professor_user("missing-committee-member@ic.uff.br")])
    expect(consolidate).not_to include(I18n.t(I18N_MISSING, count: 1))
  end

  it "não acusa quando a fase seguinte não pede comitê", pending: "issue #768" do
    expect(consolidate).not_to include(I18n.t(I18N_MISSING, count: 1))
  end

  it "não acusa quando a fase seguinte só tem formulário do candidato", pending: "issue #768" do
    @phase2.update!(candidate_form: create_admission_template("Candidato", { "x" => Admissions::FormField::STRING }))
    expect(consolidate).not_to include(I18n.t(I18N_MISSING, count: 1))
  end
end
