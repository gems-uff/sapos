# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Papel em que o usuário atua — issue #674.
#
# O Ability decide pelo papel em que o usuário atua (users.actual_role); o
# vínculo do usuário com o papel mora em outra tabela (user_roles). A regra a
# garantir é uma só: ninguém tem a permissão de um papel sem ter o vínculo.
#
# Pela tela ela se mantém, porque a gravação passa pelo User: tirado o papel em
# que o usuário atua, ele passa ao maior dos que sobraram, e tirados todos fica
# com Desconhecido (users_role_escalation_spec.rb). Fora da tela não: console,
# rake e migração de dado em SQL apagam o vínculo sem tocar no usuário, e ele
# segue com as permissões do papel que perdeu, inclusive na sessão já aberta,
# até entrar de novo.
#
# A issue decidiu também que não ter vínculo é não ter papel, e que o papel
# Desconhecido sai: ele não dá permissão nenhuma, e hoje só a tela o repõe,
# de modo que tela e script deixam o mesmo usuário em estados diferentes.
#
# As reproduções ficam pending até o conserto; quando ele chegar, o RSpec acusa
# o pending que passou, e é a hora de tirar a marca. Elas cobram a regra, não o
# conserto: passam se o banco recusar apagar o vínculo em uso, e passam se o
# Ability deixar de aceitar o papel que não é do usuário. Os controles, sem
# pending, provam que o cenário monta — com o vínculo a secretaria lê e abre a
# lista, e a tela não tem como apagar o vínculo — e fixam o que encontra quem
# fica sem papel nenhum, pela tela ou fora dela: entra, vê a página inicial e
# não alcança nada.
RSpec.describe "Papel em que o usuario atua", type: :request do
  before(:each) do
    # O formulário de usuário lista os seis papéis: precisam existir todos.
    @papel = %i[administrador coordenacao secretaria professor aluno desconhecido].index_with do |nome|
      FactoryBot.create(:"role_#{nome}")
    end
    @secretaria = create_confirmed_user([@papel[:secretaria]], "secretaria@papel.test", "Secretaria")
  end

  def vinculo?(user)
    UserRole.exists?(user_id: user.id, role_id: Role::ROLE_SECRETARIA)
  end

  def le_alunos?(user)
    Ability.new(user.reload).can?(:read, Student)
  end

  # Fora de IP local a recusa do cancancan sobe como exceção (ver
  # RouteProbe::REMOTE_ADDR); em IP local o better_errors a transforma em
  # página de erro.
  def abre_lista_de_alunos?
    get students_path, env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
    response.successful?
  rescue CanCan::AccessDenied
    false
  end

  # O caminho de fora da tela: a linha de user_roles some sem passar pelo User.
  # Se o banco recusar o apagamento, o vínculo continua lá.
  def apagar_vinculo_fora_da_tela(user)
    UserRole.where(user_id: user.id).delete_all
  rescue ActiveRecord::StatementInvalid
    nil
  end

  # A regra, pelo avesso: permissão do papel em quem já não tem o vínculo.
  def permissao_sem_vinculo?(user)
    !vinculo?(user) && yield
  end

  def entra_e_nao_alcanca_nada(user)
    sign_in user.reload
    get landing_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ainda não tem acesso a nada")
    expect(abre_lista_de_alunos?).to be(false)
    expect(le_alunos?(user)).to be(false)
  end

  describe "com o vinculo" do
    it "a secretaria le alunos e abre a lista" do
      expect(le_alunos?(@secretaria)).to be(true)

      sign_in @secretaria
      expect(abre_lista_de_alunos?).to be(true)
    end

    # A tela de vínculos de papel só lista. A rota de apagar existe, mas não há
    # ação que a atenda, e a resposta é o erro de quem não tem o que desenhar:
    # em HTML falta o template, em JS o template da gem não acha o registro.
    # O que o exemplo cobra é o banco.
    it "a tela de vinculos de papel nao apaga o vinculo, nem para o administrador" do
      administrador = create_confirmed_user([@papel[:administrador]], "adm@papel.test", "Administrador")
      vinculo = @secretaria.user_roles.first

      [{}, { xhr: true }].each do |formato|
        sign_in administrador
        begin
          delete user_role_path(vinculo), env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }, **formato
        rescue ActionController::UnknownFormat, ActionView::Template::Error
          nil
        end
      end

      expect(vinculo?(@secretaria)).to be(true)
      expect(@secretaria.reload.actual_role).to eq(Role::ROLE_SECRETARIA)
    end
  end

  describe "vinculo apagado fora da tela" do
    it "nao deixa o usuario com a permissao do papel que perdeu", pending: "issue #674" do
      apagar_vinculo_fora_da_tela(@secretaria)

      expect(permissao_sem_vinculo?(@secretaria) { le_alunos?(@secretaria) }).to be(false)
    end

    it "nao deixa a sessao ja aberta seguir abrindo a lista de alunos", pending: "issue #674" do
      sign_in @secretaria
      expect(abre_lista_de_alunos?).to be(true)

      apagar_vinculo_fora_da_tela(@secretaria)

      expect(permissao_sem_vinculo?(@secretaria) { abre_lista_de_alunos? }).to be(false)
    end
  end

  describe "quem fica sem papel nenhum" do
    # Com todos os papéis desmarcados, o formulário não manda `roles`.
    def tirar_todos_os_papeis_pela_tela(user)
      administrador = create_confirmed_user([@papel[:administrador]], "adm@papel.test", "Administrador")
      sign_in administrador
      patch user_path(user), params: { record: { name: user.name } }
      sign_out administrador
    end

    it "pela tela: entra, ve a pagina inicial e nao alcanca nada" do
      tirar_todos_os_papeis_pela_tela(@secretaria)

      entra_e_nao_alcanca_nada(@secretaria)
    end

    # Fora de requisição o current_user dos modelos é nil, e o User não repõe
    # o Desconhecido: o usuário fica como a issue decidiu que deve ficar.
    it "fora da tela, pelo model: fica sem vinculo e sem papel ativo, entra e nao alcanca nada" do
      @secretaria.roles = []
      @secretaria.save!

      expect(@secretaria.reload.roles).to be_empty
      expect(@secretaria.actual_role).to be_nil
      entra_e_nao_alcanca_nada(@secretaria)
    end

    it "pela tela, fica sem vinculo e sem papel ativo, como fora dela", pending: "issue #674" do
      tirar_todos_os_papeis_pela_tela(@secretaria)

      expect(@secretaria.reload.roles).to be_empty
      expect(@secretaria.actual_role).to be_nil
    end
  end

  # Papel atual vazio em quem tem vínculo: é como fica o usuário quando um
  # script esvazia o papel atual para poder apagar o vínculo em uso. O login
  # grava o usuário, e o User o põe no maior papel que ele tem.
  describe "papel atual vazio, com vinculo" do
    it "ao entrar, o usuario passa a atuar no maior papel que tem" do
      user = create_confirmed_user(
        [@papel[:secretaria], @papel[:professor]], "dois@papel.test", "Dois Papeis",
        professor: FactoryBot.create(:professor)
      )
      user.update_column(:actual_role, nil)
      expect(le_alunos?(user)).to be(false)

      post user_session_path, params: { user: { email: user.email, password: "A1b2c3d4!" } }

      expect(user.reload.actual_role).to eq(Role::ROLE_SECRETARIA)
      expect(abre_lista_de_alunos?).to be(true)
    end
  end

  # O User compara papéis pela posição na escada (Role::ORDER) e presume que
  # todo usuário tem ao menos um. Quem ficou sem papel fora da tela não tem
  # posição: a comparação estoura, o active_scaffold engole a exceção e a tela
  # responde "Não é possível excluir".
  describe "apagar pela tela" do
    before(:each) do
      @administrador = create_confirmed_user([@papel[:administrador]], "adm@papel.test", "Administrador")
    end

    def apagar_pela_tela(user)
      sign_in @administrador
      delete user_path(user), env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
    end

    it "o administrador apaga o usuario que tem papel" do
      apagar_pela_tela(@secretaria)

      expect(User.exists?(@secretaria.id)).to be(false)
    end

    it "o administrador apaga o usuario que ficou sem papel fora da tela", pending: "issue #674" do
      @secretaria.roles = []
      @secretaria.save!

      apagar_pela_tela(@secretaria)

      expect(User.exists?(@secretaria.id)).to be(false)
    end
  end
end
