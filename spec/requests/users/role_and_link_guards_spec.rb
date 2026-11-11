# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# As travas de User que dependem de current_user so rodam numa requisicao (ver
# "Pontos cegos da suite" no AGENTS.md), e nenhum exemplo as percorria (#720):
# rebaixar quem tem papel acima do seu, apagar quem tem papel acima do seu,
# apagar a si mesmo, e vincular um professor ou aluno que ja e de outro
# usuario. Cada recusa vem com o controle de quem passa.
RSpec.describe "Travas de papel e vinculo do usuario", type: :request do
  before(:each) do
    # O formulario de usuario lista todos os papeis pelo nome.
    @papeis = {
      desconhecido: FactoryBot.create(:role_desconhecido),
      aluno: FactoryBot.create(:role_aluno),
      professor: FactoryBot.create(:role_professor),
      secretaria: FactoryBot.create(:role_secretaria),
      coordenacao: FactoryBot.create(:role_coordenacao),
      administrador: FactoryBot.create(:role_administrador),
    }
    @admin = create_confirmed_user([@papeis[:administrador]], "adm_travas@ic.uff.br", "Adm Travas")
    @coordenacao = create_confirmed_user([@papeis[:coordenacao]], "coord_travas@ic.uff.br", "Coord Travas")
    @secretaria = create_confirmed_user([@papeis[:secretaria]], "sec_travas@ic.uff.br", "Sec Travas")
  end

  def mensagem(chave)
    CGI.escapeHTML(User.new.errors.generate_message(:base, chave))
  end

  def papeis_de(usuario)
    usuario.reload.roles.map(&:id)
  end

  describe "edicao de papel" do
    it "recusa que a coordenacao rebaixe um administrador" do
      sign_in @coordenacao

      put user_path(@admin), params: {
        record: { email: @admin.email, name: @admin.name, roles: [@papeis[:secretaria].id.to_s] }
      }

      expect(papeis_de(@admin)).to eq([@papeis[:administrador].id])
      expect(response.body).to include(mensagem(:invalid_role_was))
    end

    it "aceita que a coordenacao mude o papel de quem esta abaixo dela" do
      sign_in @coordenacao

      put user_path(@secretaria), params: {
        record: { email: @secretaria.email, name: @secretaria.name, roles: [@papeis[:desconhecido].id.to_s] }
      }

      expect(response).to have_http_status(:found)
      expect(papeis_de(@secretaria)).to eq([@papeis[:desconhecido].id])
    end
  end

  # A tela apaga por xhr e mostra a recusa na area de mensagens da lista. Pelo
  # DELETE sem xhr a recusa redireciona sem mensagem nenhuma.
  describe "exclusao" do
    it "recusa que a coordenacao apague um administrador" do
      sign_in @coordenacao

      delete user_path(@admin), xhr: true

      expect(User.exists?(@admin.id)).to be(true)
      expect(response.body).to include(
        User.new.errors.generate_message(:base, :invalid_role_full)
      )
    end

    it "recusa que o usuario apague a si mesmo" do
      sign_in @admin

      delete user_path(@admin), xhr: true

      expect(User.exists?(@admin.id)).to be(true)
      expect(response.body).to include(
        User.new.errors.generate_message(:base, :self_delete)
      )
    end

    it "aceita que o administrador apague quem esta abaixo dele" do
      sign_in @admin

      delete user_path(@secretaria), xhr: true

      expect(User.exists?(@secretaria.id)).to be(false)
    end
  end

  describe "vinculo com professor ja ligado a outro usuario" do
    before(:each) do
      # O nome do professor e propagado ao usuario dele (UserNameSyncConcern).
      @dono = create_confirmed_user([], "dono_prof@ic.uff.br", "Dono do Professor")
      @professor = FactoryBot.create(:professor, name: "Dono do Professor", user: @dono)
      @outro = create_confirmed_user([@papeis[:secretaria]], "outro_prof@ic.uff.br", "Outro")
      sign_in @admin
    end

    it "recusa e cita o usuario que ja tem o professor" do
      put user_path(@outro), params: {
        record: {
          email: @outro.email, name: @outro.name,
          roles: [@papeis[:professor].id.to_s], professor: @professor.id.to_s
        }
      }

      expect(@professor.reload.user).to eq(@dono)
      expect(response.body).to include(CGI.escapeHTML(
        User.new.errors.generate_message(
          :professor, :selected_professor_is_already_linked_to_another_user, nome_usuario: "Dono do Professor"
        )
      ))
    end
  end

  describe "vinculo com aluno ja ligado a outro usuario" do
    before(:each) do
      @dono = create_confirmed_user([], "dono_aluno@ic.uff.br", "Dono do Aluno")
      @aluno = FactoryBot.create(:student, name: "Dono do Aluno", user: @dono)
      @outro = create_confirmed_user([@papeis[:secretaria]], "outro_aluno@ic.uff.br", "Outro")
      sign_in @admin
    end

    it "recusa e cita o usuario que ja tem o aluno" do
      put user_path(@outro), params: {
        record: {
          email: @outro.email, name: @outro.name,
          roles: [@papeis[:aluno].id.to_s], student: @aluno.id.to_s
        }
      }

      expect(@aluno.reload.user).to eq(@dono)
      expect(response.body).to include(CGI.escapeHTML(
        User.new.errors.generate_message(
          :student, :selected_student_is_already_linked_to_another_user, nome_usuario: "Dono do Aluno"
        )
      ))
    end
  end
end

# Esta nao depende de current_user: vale tambem fora da requisicao.
RSpec.describe User, "papel de aluno sem aluno vinculado", type: :model do
  it "recusa o papel Aluno sem registro de aluno" do
    usuario = User.new(
      email: "aluno_sem_registro@ic.uff.br", name: "Sem Registro", password: "A1b2c3d4!",
      roles: [FactoryBot.create(:role_aluno)]
    )

    expect(usuario).not_to be_valid
    expect(usuario.errors.details[:base]).to include(error: :role_student_not_associated)
  end
end
