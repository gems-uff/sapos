# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Escalação de papel — issue #742.
#
# Quem administra usuários não alcança um papel acima do seu: não o dá a si
# nem a outro, não cria usuário com ele, e não toca em quem já o tem (trocar a
# senha ou o e-mail de um administrador seria tomar a conta dele). Quem barra é
# User#roles_valid?, que só roda dentro de uma requisição — o current_user dos
# modelos vem do active_scaffold —, e por isso nenhum spec de modelo o alcança.
#
# Cada recusa se julga pelo banco, e cada grupo tem o controle do que passa.
RSpec.describe "Escalacao de papel pela tela de usuarios", type: :request do
  SENHA = "A1b2c3d4!"

  before(:each) do
    # O formulário de usuário lista os sete papéis: precisam existir todos.
    @papel = %i[administrador coordenacao secretaria professor aluno suporte desconhecido].index_with do |nome|
      FactoryBot.create(:"role_#{nome}")
    end
    @administrador = create_confirmed_user([@papel[:administrador]], "adm@escalacao.test", "Administrador", SENHA)
    @coordenacao = create_confirmed_user([@papel[:coordenacao]], "coord@escalacao.test", "Coordenacao", SENHA)
    @comum = create_confirmed_user([@papel[:desconhecido]], "comum@escalacao.test", "Comum", SENHA)
    @dois_papeis = create_confirmed_user(
      [@papel[:secretaria], @papel[:suporte]], "dois@escalacao.test", "Dois Papeis", SENHA
    )
    @dois_papeis.update_column(:actual_role, Role::ROLE_SECRETARIA)
  end

  def papeis(user)
    user.reload.roles.map(&:id).sort
  end

  def ids(*nomes)
    nomes.map { |nome| @papel[nome].id }
  end

  def alterar(user, **record)
    patch user_path(user), params: { record: record }
  end

  describe "a coordenacao" do
    before(:each) { sign_in @coordenacao }

    it "nao da o papel de administrador a si mesma" do
      alterar(@coordenacao, roles: ids(:coordenacao, :administrador))

      expect(papeis(@coordenacao)).to eq(ids(:coordenacao))
      expect(response.body).to include(CGI.escapeHTML(I18n.t("activerecord.errors.models.user.invalid_role")))
    end

    it "nao da o papel de administrador a outro usuario" do
      alterar(@comum, roles: ids(:administrador))

      expect(papeis(@comum)).to eq(ids(:desconhecido))
    end

    it "nao cria usuario administrador" do
      expect {
        post users_path, params: { record: {
          name: "Novo", email: "novo@escalacao.test", roles: ids(:administrador),
          password: SENHA, password_confirmation: SENHA
        } }
      }.not_to change(User, :count)
    end

    it "nao troca a senha nem o e-mail de um administrador, com ou sem os papeis no formulario" do
      senha = @administrador.encrypted_password

      alterar(@administrador, roles: ids(:administrador), password: "Tomada123!", password_confirmation: "Tomada123!")
      alterar(@administrador, roles: ids(:administrador), email: "tomado@escalacao.test")
      alterar(@administrador, email: "tomado@escalacao.test")

      @administrador.reload
      expect(@administrador.encrypted_password).to eq(senha)
      expect(@administrador.email).to eq("adm@escalacao.test")
      expect(papeis(@administrador)).to eq(ids(:administrador))
    end

    it "nao apaga um administrador" do
      delete user_path(@administrador)

      expect(User.exists?(@administrador.id)).to be(true)
    end

    it "nao escolhe o papel em que outro usuario atua" do
      alterar(@comum, roles: ids(:desconhecido), actual_role: Role::ROLE_ADMINISTRADOR)

      expect(@comum.reload.actual_role).to eq(Role::ROLE_DESCONHECIDO)
    end

    # Controles: o que está à altura dela, passa.
    it "cria usuario com o proprio papel e altera quem esta abaixo" do
      expect {
        post users_path, params: { record: {
          name: "Novo", email: "novo@escalacao.test", roles: ids(:coordenacao),
          password: SENHA, password_confirmation: SENHA
        } }
      }.to change(User, :count).by(1)

      alterar(@comum, roles: ids(:secretaria))
      expect(papeis(@comum)).to eq(ids(:secretaria))
    end

    # O Ability decide pelo papel em que o usuário atua. Tirado esse papel, o
    # usuário passa a atuar no maior dos que sobraram; tirados todos, fica com
    # Desconhecido — nunca com um papel que já não é dele.
    it "ao tirar o papel em que outro usuario atua, deixa-o no maior dos que restam" do
      alterar(@dois_papeis, roles: ids(:suporte))
      expect(papeis(@dois_papeis)).to eq(ids(:suporte))
      expect(@dois_papeis.reload.actual_role).to eq(Role::ROLE_SUPORTE)

      alterar(@dois_papeis, name: "Dois Papeis")
      expect(papeis(@dois_papeis)).to eq(ids(:desconhecido))
      expect(@dois_papeis.reload.actual_role).to eq(Role::ROLE_DESCONHECIDO)
    end
  end

  describe "quem nao administra usuarios" do
    it "pelo proprio perfil, altera so o e-mail e a senha" do
      sign_in @comum

      patch user_registration_path, params: { user: {
        email: @comum.email, current_password: SENHA, name: "Outro Nome",
        actual_role: Role::ROLE_ADMINISTRADOR, role_ids: ids(:administrador), roles: ids(:administrador)
      } }

      @comum.reload
      expect(@comum.name).to eq("Comum")
      expect(@comum.actual_role).to eq(Role::ROLE_DESCONHECIDO)
      expect(papeis(@comum)).to eq(ids(:desconhecido))
    end

    it "nao troca para um papel que nao tem, e troca para um que tem" do
      sign_in @dois_papeis

      post "/change_role", params: { role_id: Role::ROLE_ADMINISTRADOR }
      expect(@dois_papeis.reload.actual_role).to eq(Role::ROLE_SECRETARIA)

      post "/change_role", params: { role_id: Role::ROLE_SUPORTE }
      expect(@dois_papeis.reload.actual_role).to eq(Role::ROLE_SUPORTE)
    end

    # Fora de IP local a recusa do cancancan sobe como exceção (ver
    # RouteProbe::REMOTE_ADDR); em IP local o better_errors a transforma em
    # página de erro.
    it "a secretaria nao lista, nao altera e nao cria usuario" do
      @dois_papeis.update_column(:actual_role, Role::ROLE_SECRETARIA)
      env = { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
      tentativas = [
        -> { get users_path, env: env },
        -> { patch user_path(@comum), params: { record: { roles: ids(:secretaria) } }, env: env },
        -> { post users_path, params: { record: { name: "Novo", email: "novo@escalacao.test" } }, env: env },
      ]

      expect {
        tentativas.each do |tentativa|
          sign_in @dois_papeis
          expect { tentativa.call }.to raise_error(CanCan::AccessDenied)
        end
      }.not_to change(User, :count)
      expect(papeis(@comum)).to eq(ids(:desconhecido))
    end
  end
end
