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
    # O formulário de usuário lista os seis papéis: precisam existir todos.
    @papel = %i[administrador coordenacao secretaria professor aluno desconhecido].index_with do |nome|
      FactoryBot.create(:"role_#{nome}")
    end
    @administrador = create_confirmed_user([@papel[:administrador]], "adm@escalacao.test", "Administrador", SENHA)
    @coordenacao = create_confirmed_user([@papel[:coordenacao]], "coord@escalacao.test", "Coordenacao", SENHA)
    @comum = create_confirmed_user([@papel[:desconhecido]], "comum@escalacao.test", "Comum", SENHA)
    @dois_papeis = create_confirmed_user(
      [@papel[:secretaria], @papel[:professor]], "dois@escalacao.test", "Dois Papeis", SENHA,
      professor: FactoryBot.create(:professor)
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
      expect(@administrador.unconfirmed_email).to be_nil
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
      alterar(@dois_papeis, roles: ids(:professor))
      expect(papeis(@dois_papeis)).to eq(ids(:professor))
      expect(@dois_papeis.reload.actual_role).to eq(Role::ROLE_PROFESSOR)

      alterar(@dois_papeis, name: "Dois Papeis")
      expect(papeis(@dois_papeis)).to eq(ids(:desconhecido))
      expect(@dois_papeis.reload.actual_role).to eq(Role::ROLE_DESCONHECIDO)
    end
  end

  # A escada inteira: desconhecido, aluno, professor, secretaria. Abaixo da
  # coordenação ninguém administra usuários, então toda tentativa de mexer
  # em papel, por qualquer das entradas que gravam usuário ou vínculo de papel,
  # tem de deixar o banco como estava: os papéis de todos, o papel em que cada
  # um atua, a senha, o e-mail, o nome e a contagem de usuários e de vínculos.
  describe "a escada dos papeis abaixo da coordenacao" do
    before(:each) do
      @atores = {
        desconhecido: @comum,
        aluno: create_confirmed_user(
          [@papel[:aluno]], "aluno@escalacao.test", "Aluno", SENHA, student: FactoryBot.create(:student)
        ),
        professor: create_confirmed_user(
          [@papel[:professor]], "professor@escalacao.test", "Professor", SENHA, professor: FactoryBot.create(:professor)
        ),
        secretaria: create_confirmed_user([@papel[:secretaria]], "secretaria@escalacao.test", "Secretaria", SENHA),
      }
      @alvo = create_confirmed_user([@papel[:desconhecido]], "alvo@escalacao.test", "Alvo", SENHA)
    end

    def retrato
      User.order(:id).map do |user|
        # O e-mail trocado pela tela fica em unconfirmed_email até a
        # confirmação, que vai para o endereço novo.
        [user.email, user.unconfirmed_email, user.name, user.encrypted_password, user.actual_role,
         user.roles.map(&:id).sort]
      end << UserRole.count
    end

    # Entra de novo a cada pedido (a recusa derruba a sessão do teste). Só a
    # recusa do cancancan é engolida: qualquer outra exceção é o pedido
    # quebrando por motivo que não é o papel, e derruba o exemplo.
    def pedir(ator, verbo, caminho, params)
      sign_in ator
      process(verbo, caminho, params: params, env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR })
    rescue CanCan::AccessDenied
      nil
    end

    # Cada entrada que grava usuário ou vínculo de papel, pedindo o papel.
    def tentativas_de_papel(ator, alvo, papel)
      nova_senha = { password: SENHA, password_confirmation: SENHA }
      {
        "dar o papel a si pela tela de usuarios" =>
          [:patch, user_path(ator), { record: { roles: papeis(ator) + [papel] } }],
        "dar o papel a outro usuario" =>
          [:patch, user_path(alvo), { record: { roles: [papel] } }],
        "criar usuario com o papel" =>
          [:post, users_path, { record: { name: "Novo", email: "novo@escalacao.test", roles: [papel], **nova_senha } }],
        "atuar no papel" =>
          [:post, "/change_role", { role_id: papel }],
        "atuar no papel pela tela de usuarios" =>
          [:patch, user_path(ator), { record: { actual_role: papel } }],
        "atuar no papel pela edicao em linha" =>
          [:post, "/users/#{ator.id}/update_column", { column: "actual_role", value: papel }],
        "pedir o papel pelo proprio perfil" =>
          [:patch, user_registration_path, { user: {
            email: ator.email, current_password: SENHA, actual_role: papel, role_ids: [papel], roles: [papel],
            user_roles_attributes: { "0" => { role_id: papel } },
          } }],
        "criar o vinculo de papel" =>
          [:post, user_roles_path, { record: { user: ator.id, role: papel } }],
        "trocar o papel do proprio vinculo" =>
          [:patch, user_role_path(ator.user_roles.first), { record: { role: papel } }],
      }
    end

    # Tomar a conta de quem está acima: trocar a senha ou o e-mail, ou apagar.
    def tentativas_de_tomada(vitima)
      {
        "trocar a senha" =>
          [:patch, user_path(vitima), { record: { password: "Tomada123!", password_confirmation: "Tomada123!" } }],
        "trocar o e-mail" =>
          [:patch, user_path(vitima), { record: { email: "tomado@escalacao.test" } }],
        "apagar" =>
          [:delete, user_path(vitima), {}],
      }
    end

    %i[desconhecido aluno professor secretaria].each do |degrau|
      it "#{degrau}: nenhuma tentativa muda papel, conta ou vinculo de ninguem" do
        ator = @atores[degrau]
        antes = retrato
        mudaram = []

        @papel.each_value do |papel|
          next if papel.id == ator.actual_role

          tentativas_de_papel(ator, @alvo, papel.id).each do |descricao, (verbo, caminho, params)|
            pedir(ator, verbo, caminho, params)
            mudaram << "#{descricao} (#{papel.name})" unless retrato == antes
          end
        end
        [@administrador, @coordenacao, @atores[:secretaria], @alvo].without(ator).each do |vitima|
          tentativas_de_tomada(vitima).each do |descricao, (verbo, caminho, params)|
            pedir(ator, verbo, caminho, params)
            mudaram << "#{descricao} de #{vitima.email}" unless retrato == antes
          end
        end

        expect(mudaram).to be_empty, "mudaram o banco: #{mudaram.join('; ')}"
      end
    end

    # Controle: os mesmos pedidos, feitos pelo administrador, mudam o banco —
    # o formato de cada um está certo, e a recusa acima é do papel. Os que
    # ficam de fora são portas que não existem para ninguém: o papel em que o
    # usuário atua não é campo da tela de usuários, a edição em linha está
    # desligada em todo scaffold, o perfil só leva e-mail e senha, e a tela de
    # vínculos de papel não cria nem altera. A troca do papel em que se atua
    # tem o controle no exemplo "troca para um que tem".
    it "controle: o administrador muda papel, cria usuario e troca senha pelos mesmos pedidos" do
      pedidos = tentativas_de_papel(@administrador, @alvo, @papel[:secretaria].id)
        .merge(tentativas_de_tomada(@atores[:professor]))
      funcionam = [
        "dar o papel a si pela tela de usuarios", "dar o papel a outro usuario", "criar usuario com o papel",
        "trocar a senha", "trocar o e-mail", "apagar",
      ]

      funcionam.each do |descricao|
        verbo, caminho, params = pedidos.fetch(descricao)
        antes = retrato
        pedir(@administrador, verbo, caminho, params)
        expect(retrato).not_to eq(antes), "#{descricao} nao mudou nada"
      end
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

      post "/change_role", params: { role_id: Role::ROLE_PROFESSOR }
      expect(@dois_papeis.reload.actual_role).to eq(Role::ROLE_PROFESSOR)
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
