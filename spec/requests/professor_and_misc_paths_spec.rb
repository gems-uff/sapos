# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Caminhos avulsos de controller que nenhum exemplo percorria (#720): o
# projeto novo aberto por professor (ja vem com ele de coordenador), a lista de
# pendencias de membro de comissao com candidatura a avaliar, a
# pre-visualizacao de configuracao de relatorio ja gravada e a troca de papel
# para um papel que o usuario nao tem.
RSpec.describe "Caminhos avulsos de controllers", type: :request do
  def professor_logado(email)
    professor = FactoryBot.create(:professor, name: "Professor Logado")
    user = create_confirmed_user([FactoryBot.create(:role_professor)], email, "Professor Logado", professor:)
    sign_in user
    [user, professor]
  end

  describe "GET /grants/new por professor" do
    it "abre o formulario com o proprio professor ja escolhido" do
      _, professor = professor_logado("prof.grant@ic.uff.br")

      get new_grant_path

      expect(response).to have_http_status(:ok)
      campo = Nokogiri::HTML(response.body).at_css("[name='record[professor]']")
      expect(campo["value"]).to eq(professor.id.to_s)
    end
  end

  describe "GET /pendencies por membro de comissao" do
    before(:each) do
      @user, = professor_logado("prof.pendencia@ic.uff.br")
      phase = FactoryBot.create(:admission_phase, name: "Fase Pendente")
      @candidatura = FactoryBot.create(:admission_application, name: "Candidata Pendente", admission_phase: phase)
      @pendencia = FactoryBot.create(
        :admission_pendency, admission_application: @candidatura, admission_phase: phase, user: @user
      )
    end

    it "lista a candidatura que o membro ainda tem de avaliar" do
      get pendencies_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Essa lista de pendências exibe apenas candidaturas não avaliadas")
      # A lista vem embutida e carrega depois, pelo data-refresh.
      embutida = Nokogiri::HTML(response.body).at_css(".pendency-type-box .active-scaffold-component")
      expect(embutida["data-refresh"]).to start_with("#{admission_applications_path}?")

      get embutida["data-refresh"], xhr: true

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Candidata Pendente")
    end

    # Controle: sem pendencia em aberto o bloco de candidaturas nao aparece.
    it "nao mostra o bloco quando a pendencia ja foi resolvida" do
      @pendencia.update!(status: Admissions::AdmissionPendency::OK)

      get pendencies_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Essa lista de pendências exibe apenas candidaturas não avaliadas")
    end
  end

  describe "POST /report_configurations/preview a partir de configuracao gravada" do
    before(:each) do
      sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.preview.cfg@ic.uff.br", "Adm")
      @config = ReportConfiguration.create!(
        name: "Configuracao Gravada", use_at_report: true, text: "Texto gravado", order: 1, scale: 1, x: 0, y: 0
      )
    end

    it "gera o PDF de previa sem alterar a configuracao gravada" do
      post preview_report_configurations_path(format: :pdf), params: {
        record_id: @config.id, record: { name: "Nome Editado", text: "Texto editado" },
      }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.body).to start_with("%PDF")
      expect(@config.reload.name).to eq("Configuracao Gravada")
      expect(@config.text).to eq("Texto gravado")
    end
  end

  # Defesa: o menu so oferece os papeis do usuario; outro papel so chega
  # forjado, ou removido depois de o menu renderizar.
  describe "POST /change_role" do
    before(:each) do
      @user, = professor_logado("prof.papel@ic.uff.br")
      @admin_role = FactoryBot.create(:role_administrador)
    end

    it "recusa papel que o usuario nao tem, sem trocar o papel atual" do
      papel_antes = @user.reload.actual_role

      post change_role_path, params: { role_id: @admin_role.id }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("activerecord.alert.invalid_role"))
      expect(@user.reload.actual_role).to eq(papel_antes)
    end
  end
end
