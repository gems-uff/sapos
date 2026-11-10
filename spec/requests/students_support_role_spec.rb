# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O papel de suporte cadastra foto e e-mail de aluno (#227): na ficha e na
# edição ele vê só esses dois campos, e só esses dois ele grava. Quem tem
# read_all_fields (gestão e professor) vê a ficha inteira.
RSpec.describe "Ficha de aluno pelo papel de suporte", type: :request do
  before(:each) do
    @aluno = FactoryBot.create(
      :student, name: "Aluno Ficha", email: "aluno.ficha@ic.uff.br",
      cpf: "98765432100", identity_number: "ID-77777", mother_name: "Mae Distinta"
    )
  end

  def entra(papel, email)
    sign_in create_confirmed_user([FactoryBot.create(papel)], email, "Usuario")
  end

  describe "o suporte" do
    before(:each) { entra(:role_suporte, "suporte.ficha@ic.uff.br") }

    it "vê na ficha só a foto e o e-mail" do
      get student_path(@aluno)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("aluno.ficha@ic.uff.br")
      expect(response.body).not_to include("98765432100", "987.654.321-00", "ID-77777", "Mae Distinta")
    end

    it "edita só a foto e o e-mail" do
      get edit_student_path(@aluno)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("aluno.ficha@ic.uff.br")
      expect(response.body).not_to include("98765432100", "ID-77777", "Mae Distinta")
    end

    it "grava o e-mail e ignora os outros campos do formulário" do
      put student_path(@aluno), params: {
        record: { email: "novo.email@ic.uff.br", cpf: "11122233344", mother_name: "Outra" }
      }

      @aluno.reload
      expect(@aluno.email).to eq("novo.email@ic.uff.br")
      expect(@aluno.cpf).to eq("98765432100")
      expect(@aluno.mother_name).to eq("Mae Distinta")
    end
  end

  # A configuração do scaffold é da classe e o suporte a restringe a cada
  # requisição; quem vem depois tem de recuperar a ficha inteira. Os dois
  # usuários nascem antes de qualquer requisição: depois dela o current_user
  # dos modelos é o da última, e o roles_valid? recusaria criar a secretaria.
  it "a secretaria vê a ficha inteira, mesmo depois de o suporte abri-la" do
    suporte = create_confirmed_user([FactoryBot.create(:role_suporte)], "suporte.antes@ic.uff.br", "Suporte")
    secretaria = create_confirmed_user([FactoryBot.create(:role_secretaria)], "secretaria.ficha@ic.uff.br", "Secretaria")
    sign_in suporte
    get student_path(@aluno)
    sign_out :user
    sign_in secretaria

    get student_path(@aluno)

    expect(response.body).to include("98765432100").or include("987.654.321-00")
    expect(response.body).to include("Mae Distinta")
  end
end
