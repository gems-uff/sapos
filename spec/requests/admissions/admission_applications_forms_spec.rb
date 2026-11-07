# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Dois formularios das candidaturas que nenhum exemplo montava (#720): a busca,
# com os selects proprios de situacao e de vinculo
# (Admissions::AdmissionApplicationsHelper), e o formulario de vinculo com
# aluno, que renderiza as colunas de criacao de Enrollment -- com os subforms e
# os selects de associacao -- no view context deste controller.
RSpec.describe "Admissions::AdmissionApplications: formularios de busca e de vinculo", type: :request do
  before(:each) do
    @admin = create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_candidaturas_forms@ic.uff.br", "Adm"
    )
    sign_in @admin
  end

  def html
    Nokogiri::HTML(response.body)
  end

  describe "busca" do
    before(:each) do
      get show_search_admission_applications_path, xhr: true
    end

    def opcoes(campo)
      html.css("select[name='search[#{campo}]'] option").map { |o| [o.text, o["value"]] }
    end

    it "abre o formulario" do
      expect(response).to have_http_status(:ok)
    end

    # Pendencia propria e "-" usam o id do usuario logado, com e sem sinal.
    it "oferece as situacoes, com a pendencia do usuario logado" do
      expect(opcoes(:status)).to eq([
        [I18n.t("active_scaffold._select_"), ""],
        ["-", (-@admin.id).to_s],
        [Admissions::AdmissionPendency::PENDENT, @admin.id.to_s],
      ] + Admissions::AdmissionApplication::STATUSES.map { |status| [status, status] })
    end

    it "oferece os vinculos com aluno e matricula" do
      expect(opcoes(:mapping)).to eq([
        [I18n.t("active_scaffold._select_"), ""],
        ["Com aluno", "student"],
        ["Com matrícula", "enrollment"],
        ["Com aluno sem matrícula", "student_no_enrollment"],
      ])
    end
  end

  describe "formulario de vinculo com aluno" do
    before(:each) do
      @level = FactoryBot.create(:level, name: "Nivel do vinculo")
      @candidatura = FactoryBot.create(:admission_application, name: "Candidata Vinculo")

      post map_student_form_admission_application_path(@candidatura), xhr: true
    end

    # A resposta xhr e JavaScript que troca o formulario; o HTML vem dentro de
    # uma string JS, com aspas e barras escapadas.
    def html_do_js
      Nokogiri::HTML(response.body.gsub('\\"', '"').gsub('\\/', "/"))
    end

    it "monta o formulario com o aluno vindo da candidatura" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Candidata Vinculo")
    end

    # O select de nivel da matricula sai do custom_level_form_column.
    it "oferece os niveis na matricula" do
      niveis = html_do_js.css("select[name='record_enrollment[level]'] option").map(&:text)
      expect(niveis).to include("Nivel do vinculo")
    end
  end
end
