# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A raiz manda todo usuario autenticado para a pagina inicial, e e o
# LandingController#index quem escolhe a tela de cada papel. Nenhum exemplo
# abria a raiz (#720).
RSpec.describe "Raiz do SAPOS", type: :request do
  it "pede login a quem nao esta autenticado" do
    get "/"

    expect(response).to redirect_to(new_user_session_path)
  end

  {
    role_administrador: {},
    role_coordenacao: {},
    role_secretaria: {},
    role_professor: { professor: -> { FactoryBot.create(:professor) } },
    role_aluno: { student: -> { FactoryBot.create(:student) } },
    role_desconhecido: {},
  }.each do |papel, associados|
    it "manda #{papel} para a pagina inicial" do
      sign_in create_confirmed_user(
        [FactoryBot.create(papel)], "raiz_#{papel}@ic.uff.br", "Usuario",
        **associados.transform_values(&:call)
      )

      get "/"

      expect(response).to redirect_to("/landing")
    end
  end
end
