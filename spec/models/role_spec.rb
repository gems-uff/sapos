# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Role, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:user_roles).dependent(:restrict_with_exception) }
  it { should have_many(:users).through(:user_roles) }

  describe "Constants" do
    it "defines the expected role ids" do
      expect(Role::ROLE_DESCONHECIDO).to eq(1)
      expect(Role::ROLE_COORDENACAO).to eq(2)
      expect(Role::ROLE_SECRETARIA).to eq(3)
      expect(Role::ROLE_PROFESSOR).to eq(4)
      expect(Role::ROLE_ALUNO).to eq(5)
      expect(Role::ROLE_ADMINISTRADOR).to eq(6)
      expect(Role::ROLE_SUPORTE).to eq(7)
    end

    it "ORDER contains all 7 roles" do
      expect(Role::ORDER).to contain_exactly(
        Role::ROLE_DESCONHECIDO,
        Role::ROLE_COORDENACAO,
        Role::ROLE_SECRETARIA,
        Role::ROLE_PROFESSOR,
        Role::ROLE_ALUNO,
        Role::ROLE_ADMINISTRADOR,
        Role::ROLE_SUPORTE
      )
    end
  end
end
