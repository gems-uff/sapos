# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require Rails.root.join("db/migrate/20261110120000_remove_suporte_role.rb")

# A migration roda uma vez, no deploy, sobre os usuarios de cada instalacao, e
# nenhum outro ponto da suite a executa (#748). Os papeis e os usuarios entram
# aqui por insert, como a migration os encontra: o codigo ja nao conhece o
# papel 7, e as validacoes de User o recusariam.
RSpec.describe RemoveSuporteRole do
  before(:each) do
    agora = Time.current
    papeis = {
      1 => "Desconhecido", 2 => "Coordenação", 3 => "Secretaria", 4 => "Professor",
      5 => "Aluno", 6 => "Administrador", 7 => "Suporte",
    }
    Role.insert_all!(
      papeis.map { |id, nome| { id: id, name: nome, description: nome, created_at: agora, updated_at: agora } }
    )
  end

  def usuario(nome, papeis, atuando:)
    agora = Time.current
    User.insert_all!([{
      name: nome, email: "#{nome}@suporte.test", encrypted_password: "x", actual_role: atuando,
      created_at: agora, updated_at: agora,
    }])
    id = User.find_by!(email: "#{nome}@suporte.test").id
    if papeis.any?
      UserRole.insert_all!(papeis.map { |papel| { user_id: id, role_id: papel, created_at: agora, updated_at: agora } })
    end
    id
  end

  def estado(user_id)
    [UserRole.where(user_id: user_id).pluck(:role_id).sort, User.where(id: user_id).pick(:actual_role)]
  end

  def migrar(direcao = :up)
    migration = described_class.new
    migration.verbose = false
    migration.public_send(direcao)
  end

  it "passa a Desconhecido quem so tinha o papel" do
    so_suporte = usuario("so-suporte", [7], atuando: 7)

    migrar

    expect(estado(so_suporte)).to eq([[1], 1])
  end

  it "deixa no maior papel que resta quem atuava como Suporte e tinha outros" do
    com_secretaria = usuario("suporte-e-secretaria", [7, 3], atuando: 7)
    com_dois = usuario("suporte-aluno-professor", [7, 5, 4], atuando: 7)
    com_coordenacao = usuario("suporte-secretaria-coordenacao", [3, 7, 2], atuando: 7)

    migrar

    expect(estado(com_secretaria)).to eq([[3], 3])
    expect(estado(com_dois)).to eq([[4, 5], 4])
    expect(estado(com_coordenacao)).to eq([[2, 3], 2])
  end

  it "tira o papel de quem atuava em outro, sem mudar o papel em que atua" do
    atuando_como_aluno = usuario("suporte-atuando-como-aluno", [7, 5, 4], atuando: 5)

    migrar

    expect(estado(atuando_como_aluno)).to eq([[4, 5], 5])
  end

  it "conserta quem atuava como Suporte sem ter o vinculo" do
    sem_vinculo = usuario("atuando-sem-vinculo", [3], atuando: 7)
    sem_papel_nenhum = usuario("atuando-sem-papel", [], atuando: 7)

    migrar

    expect(estado(sem_vinculo)).to eq([[3], 3])
    expect(estado(sem_papel_nenhum)).to eq([[1], 1])
  end

  it "nao toca em quem nao tinha o papel" do
    secretaria = usuario("secretaria", [3], atuando: 3)
    dois_papeis = usuario("professor-e-coordenacao", [4, 2], atuando: 4)
    sem_papel = usuario("sem-papel", [], atuando: nil)

    migrar

    expect(estado(secretaria)).to eq([[3], 3])
    expect(estado(dois_papeis)).to eq([[2, 4], 4])
    expect(estado(sem_papel)).to eq([[], nil])
  end

  it "tira o papel da tabela e deixa os outros seis" do
    usuario("so-suporte", [7], atuando: 7)

    migrar

    expect(Role.order(:id).pluck(:id)).to eq([1, 2, 3, 4, 5, 6])
    expect(UserRole.where(role_id: 7)).to be_empty
    expect(User.where(actual_role: 7)).to be_empty
  end

  it "deixa todo usuario afetado atuando num papel que o codigo conhece e que e dele" do
    ids = [
      usuario("a", [7], atuando: 7), usuario("b", [7, 3], atuando: 7), usuario("c", [7, 5], atuando: 5),
      usuario("d", [], atuando: 7),
    ]

    migrar

    ids.each do |id|
      papeis, atuando = estado(id)
      expect(Role::ORDER).to include(atuando)
      expect(papeis).to include(atuando)
    end
  end

  it "roda duas vezes sem mudar mais nada" do
    so_suporte = usuario("so-suporte", [7], atuando: 7)

    migrar
    migrar

    expect(estado(so_suporte)).to eq([[1], 1])
    expect(UserRole.where(user_id: so_suporte).count).to eq(1)
  end

  it "repoe a linha do papel na volta" do
    migrar
    migrar(:down)

    expect(Role.find(7).name).to eq("Suporte")
  end
end
