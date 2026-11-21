# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Mensagem "Candidatura mapeada" (issue #771): so a resposta html sem js a poe
# no flash; o formulario da tela e multipart e responde por iframe, sem ela.
RSpec.describe "Mensagem de sucesso do mapeamento", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.mapeada@ic.uff.br", "Adm")
    @level = FactoryBot.create(:level)
    @status = FactoryBot.create(:enrollment_status)
    processo = FactoryBot.create(:admission_process, level: @level, enrollment_status: @status)
    @inscricao = FactoryBot.create(:admission_application, admission_process: processo,
      name: "Cand", email: "cand.mapeada@ic.uff.br")
  end

  let(:params_mapeamento) do
    {
      record_student: { name: "Aluna Mapeada", cpf: "mapeada-cpf" },
      record_enrollment: {
        enrollment_number: "M-MAPEADA", "admission_date(1i)" => "2024", "admission_date(2i)" => "1",
        "admission_date(3i)" => "1", enrollment_status: @status.id, level: @level.id,
      },
    }
  end

  let(:sucesso) do
    I18n.t("active_scaffold.admissions/admission_application.map_student.success", student_label: "Aluna Mapeada")
  end

  it "controle: sem js, a mensagem vai no flash" do
    post map_student_form_create_update_admission_application_path(@inscricao), params: params_mapeamento
    expect(flash[:info]).to eq(sucesso)
  end

  it "controle: o formulario do mapeamento e multipart" do
    expect(StudentsController.active_scaffold_config.create.multipart? ||
      EnrollmentsController.active_scaffold_config.create.multipart?).to be(true)
  end

  it "pelo iframe, a resposta traz a mensagem", pending: "issue #771" do
    post map_student_form_create_update_admission_application_path(@inscricao),
      params: params_mapeamento.merge(iframe: "true"), headers: { "X-Requested-With" => "XMLHttpRequest" }
    expect(@inscricao.reload.student).to be_present
    expect(response.body).to include("Candidatura mapeada - Aluna Mapeada")
  end
end
