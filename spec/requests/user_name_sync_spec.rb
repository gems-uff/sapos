# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Student#sync_name_to_user grava o usuario do registro, e as validacoes de User
# dependem de current_user, que so existe dentro de uma requisicao (ver "Pontos
# cegos da suite" no AGENTS.md). Em spec de modelo o current_user e nil,
# User#roles_valid? retorna na primeira linha e o corpo que barra a gravacao
# nunca roda -- ou seja, o spec de modelo exercita o unico cenario que nao
# acontece em producao. Estes exemplos passam pela tela.
RSpec.describe "Propagacao do nome do aluno para o usuario", type: :request do
  before(:each) do
    @role_desconhecido = FactoryBot.create(:role_desconhecido)
    @role_aluno = FactoryBot.create(:role_aluno)
    @role_secretaria = FactoryBot.create(:role_secretaria)
    @role_administrador = FactoryBot.create(:role_administrador)
  end

  # O usuario nasce sem papel e recebe os papeis depois, por user_roles: User
  # valida que quem tem papel de aluno tenha registro de aluno, e o registro so
  # existe depois que o usuario existe.
  def usuario_com_papeis(papeis, tag)
    user = create_confirmed_user([], "usuario_#{tag}@ic.uff.br", "JOAO CARLOS DOS SANTOS")
    yield(user)
    papeis.each { |papel| FactoryBot.create(:user_role, user: user, role: papel) }
    user.reload
  end

  describe "aluno" do
    it "propaga o nome corrigido pela tela" do
      secretaria = create_confirmed_user([@role_secretaria], "sec1@ic.uff.br", "Secretaria")
      student = nil
      user = usuario_com_papeis([@role_aluno], "s1") do |u|
        student = Student.create!(
          name: "JOAO CARLOS DOS SANTOS", cpf: "s1",
          email: "usuario_s1@ic.uff.br", user: u
        )
      end
      sign_in secretaria

      put student_path(student), params: { record: { name: "Joao Carlos dos Santos" } }

      expect(student.reload.name).to eq("Joao Carlos dos Santos")
      expect(user.reload.name).to eq("Joao Carlos dos Santos")
    end

    # Aluno que tambem e administrador do sistema e um usuario valido e montavel
    # pela tela de usuarios. Para a secretaria que edita a ficha dele,
    # User#roles_valid? reprova a gravacao com :invalid_role, porque compara o
    # papel de quem edita com o papel mais alto de quem e editado. Uma
    # propagacao que respeitasse essa validacao salvaria o aluno, nao salvaria o
    # usuario, e devolveria 302 como se tivesse salvado os dois.
    it "propaga mesmo quando o usuario tem papel acima do de quem edita" do
      secretaria = create_confirmed_user([@role_secretaria], "sec2@ic.uff.br", "Secretaria")
      student = nil
      user = usuario_com_papeis([@role_aluno, @role_administrador], "s2") do |u|
        student = Student.create!(
          name: "JOAO CARLOS DOS SANTOS", cpf: "s2",
          email: "usuario_s2@ic.uff.br", user: u
        )
      end
      sign_in secretaria

      put student_path(student), params: { record: { name: "Joao Carlos dos Santos" } }

      expect(student.reload.name).to eq("Joao Carlos dos Santos")
      expect(user.reload.name).to eq("Joao Carlos dos Santos")

      # Controle: a validacao continua de pe. Gravar o mesmo usuario pelo
      # caminho validado, ainda dentro desta requisicao, continua sendo
      # reprovado -- o verde acima vem do bypass deliberado, nao de uma
      # validacao que sumiu.
      expect(user.update(name: "Outro Nome")).to be false
      expect(user.errors[:base]).to include(
        I18n.t("activerecord.errors.models.user.invalid_role")
      )
    end
  end
end
