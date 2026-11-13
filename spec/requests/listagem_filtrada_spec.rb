# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A listagem filtrada pelo Ability — issue #742.
#
# A listagem de todo scaffold é o accessible_by que a ponte do active_scaffold
# aplica (beginning_of_chain). A matriz do Ability
# (spec/models/ability_matrix_spec.rb) mede o accessible_by; a matriz HTTP
# (spec/requests/matriz_http/) mede o status de cada rota. Aqui se confere o
# conteúdo: a tela lista o que o accessible_by devolve, e só isso.
RSpec.describe "Listagem filtrada pelo Ability", type: :request do
  include AbilityDataset

  before(:each) do
    travel_to GoldenMaster::FROZEN_AT
    build_ability_dataset
  end
  after(:each) { travel_back }

  it "lista para o professor só as candidaturas em que ele tem pendência" do
    sign_in @users[:professor]
    get "/admission_applications", env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("app_pendente")
    expect(response.body).not_to include("app_outro", "app_compartilhada", "app_sem")
  end

  # As cinco regras de FilledForm do professor numa tela só
  # (spec/models/admissions/filled_form_rules_spec.rb): a listagem, e a mesma
  # listagem ordenada por cada coluna, que é onde o SQL do accessible_by
  # recebe o ORDER BY do active_scaffold por cima.
  describe "formularios preenchidos, para o professor" do
    def linhas_listadas
      Nokogiri::HTML(response.body).css("tr.record[data-refresh]").map { |linha| linha["data-refresh"].to_i }
    end

    def do_professor
      %w[ff_app_pendente ff_avaliacao_professor ff_carta_app_pendente ff_ranking_app_pendente ff_resultado_app_pendente]
        .map { |rotulo| @labels.key(rotulo).id }
    end

    before(:each) { sign_in @users[:professor] }

    it "lista os cinco que ele le, e so eles" do
      get "/filled_forms", env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }

      expect(response).to have_http_status(:ok)
      expect(linhas_listadas).to match_array(do_professor)
    end

    it "lista os mesmos cinco em qualquer ordenacao" do
      config = Admissions::FilledFormsController.active_scaffold_config
      colunas = config.list.columns.select { |coluna| config.columns[coluna].sortable? }
      expect(colunas).to be_present

      colunas.product(%w[ASC DESC]).each do |coluna, direcao|
        get "/filled_forms", params: { sort: coluna, sort_direction: direcao },
          env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }

        expect(response).to have_http_status(:ok), "#{coluna} #{direcao}"
        expect(linhas_listadas).to match_array(do_professor), "#{coluna} #{direcao}"
      end
    end

    it "abre o formulario da candidatura com pendencia e nao o da candidatura sem" do
      get "/filled_forms/#{@labels.key('ff_app_pendente').id}", env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
      expect(response).to have_http_status(:ok)

      sign_in @users[:professor]
      expect {
        get "/filled_forms/#{@labels.key('ff_app_sem').id}", env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  it "lista para a secretaria todas as candidaturas" do
    sign_in @users[:secretaria]
    get "/admission_applications", env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }

    expect(response.body).to include("app_pendente", "app_outro", "app_compartilhada", "app_sem")
  end
end
