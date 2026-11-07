# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Trocar a senha muda o sal que o Devise guarda na sessao, e a sessao de quem
# trocou deixaria de valer na requisicao seguinte. UsersController#after_update_save
# chama bypass_sign_in quando quem e editado e o proprio usuario, e nenhum
# exemplo passava por ali (#720): um update do Devise que mudasse esse contrato
# derrubaria o administrador logo depois de trocar a propria senha.
RSpec.describe "Administrador troca a propria senha pela tela de usuarios", type: :request do
  before(:each) do
    @papel = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@papel], "admin_senha@ic.uff.br", "Admin")
    sign_in @admin
  end

  def troca_senha(usuario, senha)
    put user_path(usuario), params: { record: {
      email: usuario.email, name: usuario.name, roles: [@papel.id.to_s],
      password: senha, password_confirmation: senha
    } }
  end

  it "grava a senha nova e continua logado" do
    troca_senha(@admin, "NovaSenha#2026")

    expect(@admin.reload.valid_password?("NovaSenha#2026")).to be true
    get users_path
    expect(response).to have_http_status(:ok)
  end

  it "trocar a senha de outro usuario nao mexe na sessao de quem troca" do
    outro = create_confirmed_user([@papel], "outro_senha@ic.uff.br", "Outro")

    troca_senha(outro, "OutraSenha#2026")

    expect(outro.reload.valid_password?("OutraSenha#2026")).to be true
    get users_path
    expect(response).to have_http_status(:ok)
  end
end
