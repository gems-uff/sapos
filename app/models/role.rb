# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a user Role
class Role < ApplicationRecord
  has_paper_trail

  has_many :user_roles, dependent: :restrict_with_exception
  has_many :users, through: :user_roles

  ROLE_DESCONHECIDO = 1
  ROLE_COORDENACAO = 2
  ROLE_SECRETARIA = 3
  ROLE_PROFESSOR = 4
  ROLE_ALUNO = 5
  ROLE_ADMINISTRADOR = 6
  ROLE_SUPORTE = 7

  ORDER = [
    ROLE_DESCONHECIDO,
    ROLE_ALUNO,
    ROLE_SUPORTE,
    ROLE_PROFESSOR,
    ROLE_SECRETARIA,
    ROLE_COORDENACAO,
    ROLE_ADMINISTRADOR
  ]
end
