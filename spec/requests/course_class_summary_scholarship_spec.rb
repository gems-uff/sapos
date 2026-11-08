# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A lista de alunos do resumo da turma marca com asterisco quem tem bolsa
# ativa (#720); o cenario do baseline nao tinha bolsista, entao o asterisco
# nunca saia.
RSpec.describe "Resumo da turma com aluno bolsista", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_resumo_bolsa@ic.uff.br", "Adm"
    )
    @level = FactoryBot.create(:level)
    @turma = FactoryBot.create(:course_class)
  end

  def inscreve(nome)
    matricula = FactoryBot.create(
      :enrollment, level: @level, student: FactoryBot.create(:student, name: nome)
    )
    FactoryBot.create(:class_enrollment, course_class: @turma, enrollment: matricula)
    matricula
  end

  it "marca so o aluno com bolsa ativa" do
    bolsista = inscreve("Aluna Bolsista")
    FactoryBot.create(:scholarship_duration, enrollment: bolsista)
    inscreve("Aluno Sem Bolsa")

    get summary_pdf_course_class_path(@turma, format: :pdf)

    expect(response).to have_http_status(:ok)
    texto = pdf_representation(response.body)
    expect(texto).to include("Aluna Bolsista *")
    expect(texto).to include("Aluno Sem Bolsa")
    expect(texto).not_to include("Aluno Sem Bolsa *")
  end
end
