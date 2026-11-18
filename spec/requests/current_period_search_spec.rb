# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# As três telas de período (Credenciamento, Filiação, Conceito CAPES) ganharam
# o mesmo filtro "Vigente", que traduz Sim/Não num id IN/NOT IN sobre o
# on_date(hoje) do modelo -- CurrentPeriodSearchConcern. O branco, que não
# filtra, está em field_search_neutral_options_spec.rb. O caso que a
# comparação ingênua ("término >= hoje") perdia é o período em aberto: logo
# depois do deploy, antes de qualquer término ser preenchido, ele tinha de
# entrar em "Vigente: Sim" mesmo assim.
RSpec.describe "Busca por período vigente", type: :request do
  before(:each) do
    @role_administrador = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_administrador], "adm_vigente@ic.uff.br", "Administrador")
    sign_in @admin
  end

  shared_examples "filtro de vigência" do
    it "Sim traz só os vigentes, inclusive o período em aberto" do
      get path, params: { search: { active: "1" } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(aberto_marker)
      expect(response.body).to include(vigente_marker)
      expect(response.body).not_to include(encerrado_marker)
      expect(response.body).not_to include(futuro_marker)
    end

    it "Não traz os encerrados e os futuros, não os vigentes" do
      get path, params: { search: { active: "0" } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(encerrado_marker)
      expect(response.body).to include(futuro_marker)
      expect(response.body).not_to include(aberto_marker)
      expect(response.body).not_to include(vigente_marker)
    end
  end

  describe "Credenciamentos" do
    let(:path) { advisement_authorizations_path }
    let(:level) { FactoryBot.create(:level, name: "Nível da sonda de vigência") }

    before(:each) do
      @aberto = FactoryBot.create(:professor, name: "Sonda Aberta", cpf: "aberto")
      @vigente = FactoryBot.create(:professor, name: "Sonda Vigente", cpf: "vigente")
      @encerrado = FactoryBot.create(:professor, name: "Sonda Encerrada", cpf: "encerrado")
      @futuro = FactoryBot.create(:professor, name: "Sonda Futura", cpf: "futuro")
      FactoryBot.create(:advisement_authorization, professor: @aberto, level: level,
                        start_date: Date.current - 10.days, end_date: nil)
      FactoryBot.create(:advisement_authorization, professor: @vigente, level: level,
                        start_date: Date.current - 10.days, end_date: Date.current + 10.days)
      FactoryBot.create(:advisement_authorization, professor: @encerrado, level: level,
                        start_date: Date.current - 20.days, end_date: Date.current - 10.days)
      FactoryBot.create(:advisement_authorization, professor: @futuro, level: level,
                        start_date: Date.current + 10.days, end_date: nil)
    end

    let(:aberto_marker) { @aberto.name }
    let(:vigente_marker) { @vigente.name }
    let(:encerrado_marker) { @encerrado.name }
    let(:futuro_marker) { @futuro.name }

    include_examples "filtro de vigência"
  end

  describe "Filiações" do
    let(:path) { "/affiliation" }

    before(:each) do
      @aberto = FactoryBot.create(:institution, name: "Instituição Aberta")
      @vigente = FactoryBot.create(:institution, name: "Instituição Vigente")
      @encerrado = FactoryBot.create(:institution, name: "Instituição Encerrada")
      @futuro = FactoryBot.create(:institution, name: "Instituição Futura")
      FactoryBot.create(:affiliation, professor: FactoryBot.create(:professor), institution: @aberto,
                        start_date: Date.current - 10.days, end_date: nil)
      FactoryBot.create(:affiliation, professor: FactoryBot.create(:professor), institution: @vigente,
                        start_date: Date.current - 10.days, end_date: Date.current + 10.days)
      FactoryBot.create(:affiliation, professor: FactoryBot.create(:professor), institution: @encerrado,
                        start_date: Date.current - 20.days, end_date: Date.current - 10.days)
      FactoryBot.create(:affiliation, professor: FactoryBot.create(:professor), institution: @futuro,
                        start_date: Date.current + 10.days, end_date: nil)
    end

    let(:aberto_marker) { @aberto.name }
    let(:vigente_marker) { @vigente.name }
    let(:encerrado_marker) { @encerrado.name }
    let(:futuro_marker) { @futuro.name }

    include_examples "filtro de vigência"
  end

  describe "Conceitos CAPES" do
    let(:path) { program_levels_path }

    before(:each) do
      @aberto = gravar_sem_validar(level: 3, ordinance: "Sonda Aberta",
                                   start_date: Date.current - 10.days, end_date: nil)
      @vigente = gravar_sem_validar(level: 4, ordinance: "Sonda Vigente",
                                    start_date: Date.current - 10.days, end_date: Date.current + 10.days)
      @encerrado = gravar_sem_validar(level: 5, ordinance: "Sonda Encerrada",
                                      start_date: Date.current - 20.days, end_date: Date.current - 10.days)
      @futuro = gravar_sem_validar(level: 6, ordinance: "Sonda Futura",
                                   start_date: Date.current + 10.days, end_date: nil)
    end

    # Os quatro se cruzam de propósito, para poder gravar os quatro casos de
    # borda com poucas linhas; a validação de sobreposição os recusaria.
    def gravar_sem_validar(**atributos)
      FactoryBot.build(:program_level, **atributos).tap { |record| record.save!(validate: false) }
    end

    let(:aberto_marker) { @aberto.ordinance }
    let(:vigente_marker) { @vigente.ordinance }
    let(:encerrado_marker) { @encerrado.ordinance }
    let(:futuro_marker) { @futuro.ordinance }

    include_examples "filtro de vigência"
  end
end
