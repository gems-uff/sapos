# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O lado da negacao que nenhum exemplo percorria (#720): os `cannot` com bloco
# da Ability, que o cancancan avalia por registro, e as telas que mudam de forma
# conforme o `can?`. Cada negacao vem com o controle de quem passa, para que o
# vermelho de um update do cancancan aponte a regra e nao a montagem.
#
# A recusa aparece como 500: CanCan::AccessDenied nao tem mapeamento em
# rescue_responses (o mesmo registro esta em student_enrollment_spec.rb).
RSpec.describe "Negacoes do cancancan", type: :request do
  before(:each) do
    @level = FactoryBot.create(:level)
    @student = FactoryBot.create(:student, name: "Ana")
  end

  def professor(email)
    create_confirmed_user(
      [FactoryBot.create(:role_professor)], email, "Prof",
      professor: FactoryBot.create(:professor)
    )
  end

  def matricula(status)
    FactoryBot.create(
      :enrollment, student: @student, level: @level, enrollment_status: status
    )
  end

  describe "boletim pedido por professor" do
    before(:each) do
      sign_in professor("prof_boletim@ic.uff.br")
    end

    it "recusa quando a situacao da matricula nao deixa o professor gerar" do
      fechada = matricula(FactoryBot.create(:enrollment_status, professor_can_generate_report: false))

      get grades_report_pdf_enrollment_path(fechada, format: :pdf)

      expect(response).to have_http_status(:internal_server_error)
    end

    it "gera quando a situacao deixa" do
      aberta = matricula(FactoryBot.create(:enrollment_status, professor_can_generate_report: true))

      get grades_report_pdf_enrollment_path(aberta, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
    end
  end

  describe "historico escolar sem defesa aprovada" do
    before(:each) { @sem_defesa = matricula(FactoryBot.create(:enrollment_status)) }

    it "recusa ao professor" do
      sign_in professor("prof_hist@ic.uff.br")

      get academic_transcript_pdf_enrollment_path(@sem_defesa, format: :pdf)

      expect(response).to have_http_status(:internal_server_error)
    end

    it "gera para o administrador, que a regra poupa" do
      sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_hist@ic.uff.br", "Adm")

      get academic_transcript_pdf_enrollment_path(@sem_defesa, format: :pdf)

      expect(response).to have_http_status(:ok)
    end
  end

  # StudentsController#check_current_user troca as colunas do formulario pelo
  # can?: quem so pode a foto ve foto e e-mail.
  describe "ficha do aluno editada pelo suporte" do
    it "mostra so a foto e o e-mail" do
      sign_in create_confirmed_user([FactoryBot.create(:role_suporte)], "suporte@ic.uff.br", "Suporte")

      get edit_student_path(@student)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="record[email]"')
      expect(response.body).to include('name="record[photo]"')
      expect(response.body).not_to include('name="record[name]"')
    end

    it "mostra a ficha inteira ao administrador" do
      sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_ficha@ic.uff.br", "Adm")

      get edit_student_path(@student)

      expect(response.body).to include('name="record[name]"')
    end
  end
end

# Admissions::LetterRequestsHelper#access_token_column: so quem gerencia a carta
# ganha o link de preenchimento; o resto le o token. A Ability e a real.
RSpec.describe Admissions::LetterRequestsHelper, type: :helper do
  let(:carta) { FactoryBot.create(:letter_request) }

  def com_papel(papel, **associados)
    usuario = create_confirmed_user(
      [FactoryBot.create(papel)], "carta_#{papel}@ic.uff.br", "Usuario", **associados
    )
    # O can? da view delega ao controller, que pede o usuario ao Warden.
    allow(controller).to receive(:current_ability).and_return(Ability.new(usuario))
  end

  it "da o link a quem gerencia" do
    com_papel(:role_administrador)

    expect(helper.access_token_column(carta, nil)).to include("<a ", carta.access_token)
  end

  it "da so o token a quem nao gerencia" do
    com_papel(:role_professor, professor: FactoryBot.create(:professor))

    expect(helper.access_token_column(carta, nil)).to eq(carta.access_token)
  end
end
