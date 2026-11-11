# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A lista do active_scaffold aceitava como filtro qualquer parâmetro da URL com
# nome de coluna do banco do modelo: igualdade (?coluna=valor), faixa em número
# e data (?coluna=a..b) e diferença (?coluna!=valor). Quem lista um modelo
# confirmava assim, pelo que a lista devolve, o valor de uma coluna que nenhuma
# tela lhe mostra. Agora só filtra a coluna que o controller declara em
# active_scaffold_list_url_columns: hoje, o processo e a fase na lista de
# candidaturas, que a tela de situação do processo abre uma vez por fase.
RSpec.describe "Lista dos scaffolds e parametros da URL", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  include AbilityDataset
  include RouteProbe

  def linhas
    Nokogiri::HTML(response.body).css("tr.record[data-refresh]").map { |linha| linha["data-refresh"].to_i }
  end

  def remoto
    { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
  end

  describe "em toda lista" do
    before(:each) do
      travel_to GoldenMaster::FROZEN_AT
      build_ability_dataset
      sign_in vestir_perfil(perfil("administrador"))
    end
    after(:each) { travel_back }

    it "lista os mesmos registros quando a URL traz uma coluna de texto do modelo" do
      filtraram = []
      conferidos = 0
      RouteProbe.routes.select { |rota| rota.action == "index" && rota.journey.required_parts.empty? }.each do |rota|
        controller = "#{rota.controller.camelize}Controller".safe_constantize
        next unless controller.respond_to?(:active_scaffold_config)

        config = begin
          controller.active_scaffold_config
        rescue StandardError
          nil
        end
        next if config.nil?

        declaradas = controller.new.send(:active_scaffold_list_url_columns).map(&:to_s)
        coluna = config.model.columns.find { |c| %i[string text].include?(c.type) && declaradas.exclude?(c.name) }
        next if coluna.nil?

        caminho = route_path(rota, id: nil)
        get caminho, env: remoto
        sem_parametro = linhas
        next if response.status != 200 || sem_parametro.empty?

        conferidos += 1
        get caminho, params: { coluna.name => "valor-que-nenhum-registro-tem" }, env: remoto
        filtraram << "#{caminho}?#{coluna.name}=" unless linhas == sem_parametro
      end

      expect(conferidos).to be > 30
      expect(filtraram).to be_empty, "o parametro da URL filtrou a lista: #{filtraram.join(', ')}"
    end

    it "so declara filtro pela URL a lista de candidaturas" do
      Rails.application.eager_load!
      scaffolds = ApplicationController.descendants.select { |c| c.include?(ActiveScaffold::Actions::Core) }
      declaram = scaffolds.filter_map do |controller|
        colunas = controller.new.send(:active_scaffold_list_url_columns)
        [controller.name, colunas.map(&:to_s)] if colunas.present?
      end

      expect(scaffolds.size).to be > 60

      expect(declaram).to eq(
        [["Admissions::AdmissionApplicationsController", %w[admission_process_id admission_phase_id]]]
      )
    end
  end

  # O caso que importa: quem lista os alunos sem ver o CPF de cada um.
  describe "na lista de alunos, para o professor" do
    before(:each) do
      sign_in professor_user("lista-professor@example.com")
      @alfa = FactoryBot.create(:student, name: "Alfa Um", cpf: "111.111.111-11")
      @beta = FactoryBot.create(:student, name: "Beta Dois", cpf: "222.222.222-22")
    end

    it "nao confirma o CPF: o certo e o errado listam igual" do
      get "/students", params: { cpf: "111.111.111-11" }, env: remoto
      com_o_certo = linhas

      get "/students", params: { cpf: "999.999.999-99" }, env: remoto

      expect(com_o_certo).to match_array([@alfa.id, @beta.id])
      expect(linhas).to match_array([@alfa.id, @beta.id])
    end

    it "nao confirma o CPF pela diferenca" do
      get "/students", params: { "cpf!" => "111.111.111-11" }, env: remoto

      expect(linhas).to match_array([@alfa.id, @beta.id])
    end

    it "nao filtra por faixa de uma coluna de data" do
      get "/students", params: { created_at: "2000-01-01..2000-12-31" }, env: remoto

      expect(linhas).to match_array([@alfa.id, @beta.id])
    end

    # Controles: a lista de um registro só, pelo id, e a busca da tela seguem
    # filtrando -- o cenário filtra quando o filtro é o que a tela oferece.
    it "segue listando um registro so pelo id" do
      get "/students", params: { id: @alfa.id }, env: remoto

      expect(linhas).to eq([@alfa.id])
    end

    it "segue filtrando pela busca da tela" do
      get "/students", params: { search: "Alfa" }, env: remoto

      expect(linhas).to eq([@alfa.id])
    end
  end

  # O filtro que o SAPOS usa: a situação do processo seletivo abre a lista de
  # candidaturas uma vez por fase, com o processo e a fase na URL; a fase vazia
  # é a das candidaturas que ainda não entraram em fase nenhuma.
  describe "na lista de candidaturas" do
    before(:each) do
      sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "lista-admin@example.com")
      template = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
      @processo = create_closed_admission_process(template, simple_url: "lista-um")
      outro_processo = create_closed_admission_process(template, simple_url: "lista-dois")
      @fase = add_phase(@processo, 1, name: "Analise")
      @sem_fase = create_application(@processo, name: "Sem fase")
      @na_fase = create_application(@processo, name: "Na fase", admission_phase: @fase)
      @de_outro = create_application(outro_processo, name: "De outro processo")
    end

    def listar(parametros)
      get "/admission_applications", params: parametros, env: remoto
      expect(response).to have_http_status(:ok)
      linhas
    end

    it "lista as candidaturas do processo" do
      expect(listar(admission_process_id: @processo.id)).to match_array([@sem_fase.id, @na_fase.id])
    end

    it "lista as candidaturas do processo que estao na fase" do
      expect(listar(admission_process_id: @processo.id, admission_phase_id: @fase.id)).to eq([@na_fase.id])
    end

    it "lista, com a fase vazia, as candidaturas do processo que nao estao em fase nenhuma" do
      expect(listar(admission_process_id: @processo.id, admission_phase_id: "")).to eq([@sem_fase.id])
    end

    it "abre cada lista da situacao do processo com o processo e a fase" do
      get phase_status_admission_process_path(@processo), env: remoto

      listas = Nokogiri::HTML(response.body).css("iframe").map do |quadro|
        Rack::Utils.parse_nested_query(URI(quadro["src"]).query)
      end
      expect(listas.map { |lista| lista.slice("admission_process_id", "admission_phase_id") }).to match_array([
        { "admission_process_id" => @processo.id.to_s, "admission_phase_id" => "" },
        { "admission_process_id" => @processo.id.to_s, "admission_phase_id" => @fase.id.to_s },
      ])
    end

    it "compara por igualdade, e ignora o parametro em outra forma" do
      todas = [@sem_fase.id, @na_fase.id, @de_outro.id]

      expect(listar("admission_process_id!" => @processo.id)).to match_array(todas)
      expect(listar(admission_process_id: { x: "1" })).to match_array(todas)
      expect(listar(admission_process_id: [@processo.id])).to match_array(todas)
      expect(listar(admission_process_id: "#{@processo.id}..#{@processo.id + 100}")).to match_array([@sem_fase.id, @na_fase.id])
    end

    it "nao filtra por coluna que a lista nao declara" do
      expect(listar(token: @sem_fase.token)).to match_array([@sem_fase.id, @na_fase.id, @de_outro.id])
    end
  end
end
