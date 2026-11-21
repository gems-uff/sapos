# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A edição em linha do active_scaffold (clicar na célula da lista e alterar o
# valor ali) tem duas rotas em todo scaffold: GET render_field, que devolve o
# campo com o valor, e POST update_column, que grava. A gem as aceita para
# qualquer coluna do scaffold, ofereça-a a lista ou não, e grava antes de
# passar pelo que o formulário de cada tela confere. O SAPOS não liga a edição
# em linha em coluna nenhuma (inplace_edit), então as duas rotas só respondem
# pela coluna que algum scaffold vier a ligar.
RSpec.describe "Edicao em linha dos scaffolds", type: :request do
  def remoto
    { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
  end

  it "nao esta ligada em coluna nenhuma" do
    Rails.application.eager_load!
    ligadas = ApplicationController.descendants.select { |c| c.respond_to?(:active_scaffold_config) }.flat_map do |controller|
      config = begin
        controller.active_scaffold_config
      rescue StandardError
        nil
      end
      next [] if config.nil?

      config.columns.filter_map { |coluna| "#{controller.name}##{coluna.name}" if coluna.inplace_edit }
    end

    expect(ligadas).to eq([])
  end

  describe "para o administrador, que pode alterar o registro inteiro" do
    before(:each) do
      sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "linha-admin@example.com")
      @aluno = FactoryBot.create(:student, name: "Nome Original")
    end

    it "nao grava pela edicao em linha, e a recusa nao traz o valor da coluna" do
      begin
        post "/students/#{@aluno.id}/update_column", xhr: true, env: remoto,
          params: { column: "name", value: "Nome Trocado", record: { x: "1" } }
      rescue ActiveScaffold::ActionNotAllowed
        nil
      end

      expect(@aluno.reload.name).to eq("Nome Original")
      expect(response&.body.to_s).not_to include("Nome Original")
    end

    it "recusa a coluna que nao existe sem quebrar" do
      post "/students/#{@aluno.id}/update_column", xhr: true, env: remoto,
        params: { column: "coluna_que_nao_existe", value: "x" }
    rescue ActiveScaffold::ActionNotAllowed
      nil
    else
      expect(response.status).to be_between(400, 499)
    end

    it "nao devolve o campo com o valor" do
      get "/students/#{@aluno.id}/render_field", xhr: true, env: remoto, params: { update_column: "name" }
    rescue ActiveScaffold::ActionNotAllowed
      nil
    else
      expect(response.body).not_to include("Nome Original")
    end

    # Controle: o formulário segue gravando a mesma coluna.
    it "grava a mesma coluna pelo formulario" do
      patch "/students/#{@aluno.id}", env: remoto, params: { record: { name: "Nome Trocado" } }

      expect(@aluno.reload.name).to eq("Nome Trocado")
    end
  end

  # O caso que motivou: o membro da comissão altera a candidatura em que tem
  # pendência só pelos formulários de fase.
  describe "para o membro da comissao, sobre a candidatura com pendencia" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      admin = create_confirmed_user([role], "linha-comissao-admin@example.com")
      allow(Notifier).to receive(:send_emails)
      _, @kim, @membro = application_awaiting_committee(admin)
      sign_in @membro
    end

    it "nao grava o codigo, o e-mail nem a situacao" do
      antes = @kim.attributes.slice("token", "email", "status")
      { "token" => "AAAAAA-AAAAAA-AAAAAA", "email" => "membro@example.com",
        "status" => Admissions::AdmissionApplication::APPROVED }.each do |coluna, valor|
        sign_in @membro
        begin
          post "/admission_applications/#{@kim.id}/update_column", xhr: true, env: remoto,
            params: { column: coluna, value: valor, record: { x: "1" } }
        rescue ActiveScaffold::ActionNotAllowed
          nil
        end
      end

      expect(@kim.reload.attributes.slice("token", "email", "status")).to eq(antes)
    end

    it "nao recebe o codigo inteiro no campo da edicao em linha" do
      begin
        get "/admission_applications/#{@kim.id}/render_field", xhr: true, env: remoto,
          params: { update_column: "token" }
      rescue ActiveScaffold::ActionNotAllowed
        nil
      end

      expect(response&.body.to_s).not_to include(@kim.token)
    end
  end
end
