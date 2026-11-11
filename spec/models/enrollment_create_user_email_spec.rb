# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Usuario criado pela matricula (issue #762): User.invite! nao roda a
# conferencia de formato do User; e quando o devise recusa, create_user!
# responde true sem ter criado.
RSpec.describe Enrollment, "#create_user! e o e-mail do aluno", type: :model do
  before(:each) do
    FactoryBot.create(:role_aluno) unless Role.exists?(Role::ROLE_ALUNO)
    @status = FactoryBot.create(:enrollment_status, user: true)
  end

  # Aluno gravado antes da conferencia de formato, com o endereco que for.
  def aluno_com(email)
    aluno = FactoryBot.create(:student, email: "provisorio#{SecureRandom.hex(3)}@example.com")
    aluno.update_column(:email, email)
    Student.find(aluno.id)
  end

  it "controle: endereco valido cria o usuario e o liga ao aluno" do
    aluno = aluno_com("valido.matricula@example.com")
    FactoryBot.create(:enrollment, student: aluno, enrollment_status: @status)
    expect(aluno.reload.user&.email).to eq("valido.matricula@example.com")
  end

  it "controle: o User recusa o endereco com acento" do
    expect(User.new(name: "x", email: "joão.matricula@example.com").tap(&:valid?).errors[:email]).to be_present
  end

  it "nao cria usuario com endereco que o User recusa", pending: "issue #762" do
    FactoryBot.create(:enrollment, student: aluno_com("joão.matricula@example.com"), enrollment_status: @status)
    expect(User.find_by(email: "joão.matricula@example.com")).to be_nil
  end

  it "create_user! diz false quando nao cria", pending: "issue #762" do
    aluno = aluno_com("sem-arroba.example.com")
    matricula = FactoryBot.create(:enrollment, student: aluno, enrollment_status: FactoryBot.create(:enrollment_status, user: false))
    matricula.update!(enrollment_status: @status)
    expect(matricula.create_user!).to be(false)
  end
end
