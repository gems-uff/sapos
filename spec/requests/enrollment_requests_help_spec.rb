# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A ajuda das solicitacoes de inscricao nao tem metodo de acao: o Rails
# renderiza enrollment_requests/help.html.erb direto, e quem barra o acesso e o
# authorize_resource (help e alias de read na Ability). Nenhum request spec
# abria a rota (#720).
RSpec.describe "Ajuda das solicitacoes de inscricao", type: :request do
  it "abre para quem le as solicitacoes" do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_ajuda@ic.uff.br", "Adm")

    get help_enrollment_requests_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Durante a inscrição online")
  end

  it "abre tambem pelo link do active_scaffold, que pede por XHR" do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_ajuda@ic.uff.br", "Adm")

    get help_enrollment_requests_path, xhr: true

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Durante a inscrição online")
  end

  # A recusa aparece como 500: CanCan::AccessDenied nao tem mapeamento em
  # rescue_responses (ver cancancan_denials_spec.rb).
  it "recusa a quem nao le as solicitacoes" do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_aluno)], "aluno_ajuda@ic.uff.br", "Aluno",
      student: FactoryBot.create(:student)
    )

    get help_enrollment_requests_path

    expect(response).to have_http_status(:internal_server_error)
  end
end
