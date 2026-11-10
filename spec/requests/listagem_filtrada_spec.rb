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

  it "lista para a secretaria todas as candidaturas" do
    sign_in @users[:secretaria]
    get "/admission_applications", env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }

    expect(response.body).to include("app_pendente", "app_outro", "app_compartilhada", "app_sem")
  end
end
