# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O seletor de registros (record_select) aceitava como filtro qualquer
# parâmetro da URL com nome de coluna do modelo, e coluna de texto entrava por
# LIKE com o padrão que vinha da URL. Quem abre o seletor de um modelo
# confirmava assim, um pedaço de cada vez, o valor de uma coluna que nenhuma
# tela lhe mostra. Agora só filtra a coluna que o controller do seletor
# declara em record_select_url_columns: hoje, o tipo do modelo de formulário,
# que os formulários do processo seletivo mandam para oferecer só os modelos
# do tipo certo.
RSpec.describe "Seletor de registros e parametros da URL", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  include AbilityDataset
  include RouteProbe

  def itens
    Nokogiri::HTML(response.body).css("li.record").map { |item| item["id"] }
  end

  describe "em todo seletor" do
    before(:each) do
      travel_to GoldenMaster::FROZEN_AT
      build_ability_dataset
      sign_in vestir_perfil(perfil("administrador"))
    end
    after(:each) { travel_back }

    it "lista os mesmos registros quando a URL traz uma coluna de texto do modelo" do
      filtraram = []
      conferidos = 0
      RouteProbe.routes.select { |rota| rota.action == "browse" && rota.journey.required_parts.empty? }.each do |rota|
        controller = "#{rota.controller.camelize}Controller".constantize
        config = controller.respond_to?(:record_select_config) && controller.record_select_config
        next unless config

        modelo = config.model
        declaradas = controller.new.send(:record_select_url_columns).map(&:to_s)
        coluna = modelo.columns.find { |c| %i[string text].include?(c.type) && declaradas.exclude?(c.name) }
        next if coluna.nil?

        caminho = route_path(rota, id: nil)
        get caminho
        sem_parametro = itens
        next if response.status != 200 || sem_parametro.empty?

        conferidos += 1
        get caminho, params: { coluna.name => "valor-que-nenhum-registro-tem" }
        filtraram << "#{caminho}?#{coluna.name}=" unless itens == sem_parametro
      end

      expect(conferidos).to be > 10
      expect(filtraram).to be_empty, "o parametro da URL filtrou o seletor: #{filtraram.join(', ')}"
    end
  end

  # O filtro que o SAPOS usa: o formulário do processo seletivo abre o seletor
  # de modelos com o tipo na URL (options[:params] da coluna).
  describe "no seletor de modelos de formulario" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      sign_in create_confirmed_user([role], "seletor-modelos@example.com")
      create_admission_template("Modelo de inscricao", { "Dado" => Admissions::FormField::STRING })
      create_admission_template(
        "Modelo de carta", { "Parecer" => Admissions::FormField::STRING },
        template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
      )
    end

    it "lista so os modelos do tipo pedido" do
      get browse_form_templates_path, params: { template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER }

      expect(response.body).to include("Modelo de carta")
      expect(response.body).not_to include("Modelo de inscricao")
    end

    it "compara o tipo por igualdade: curinga nao lista tudo, e parametro em outra forma e ignorado" do
      get browse_form_templates_path, params: { template_type: "%" }
      expect(response.body).not_to include("Modelo de carta", "Modelo de inscricao")

      get browse_form_templates_path, params: { template_type: { x: "1" } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Modelo de carta", "Modelo de inscricao")
    end

    it "lista todos sem o tipo, e nao filtra por coluna que o seletor nao declara" do
      get browse_form_templates_path, params: { name: "Modelo de carta" }

      expect(response.body).to include("Modelo de carta", "Modelo de inscricao")
    end

    it "manda o tipo no endereco do seletor do formulario do processo" do
      get new_admission_process_path

      expect(response).to have_http_status(:ok)
      expect(CGI.unescape(response.body)).to include(
        "template_type=#{Admissions::FormTemplate::ADMISSION_FORM}",
        "template_type=#{Admissions::FormTemplate::RECOMMENDATION_LETTER}"
      )
    end
  end

  # O caso que importa: o código da inscrição, de que o membro da comissão só
  # vê o identificador.
  describe "no seletor de candidaturas, para o membro da comissao" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      admin = create_confirmed_user([role], "seletor-admin@example.com")
      allow(Notifier).to receive(:send_emails)
      _, @kim, membro = application_awaiting_committee(admin)
      sign_in membro
    end

    it "nao confirma o comeco do codigo: o certo e o errado listam igual" do
      get browse_admission_applications_path, params: { token: "#{@kim.token[0, 9].downcase}%" }
      com_o_comeco_certo = itens

      get browse_admission_applications_path, params: { token: "zzzzzzzzz%" }
      com_o_comeco_errado = itens

      expect(com_o_comeco_certo).to be_present
      expect(com_o_comeco_errado).to eq(com_o_comeco_certo)
    end
  end
end
