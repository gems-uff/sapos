# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Role < ActiveRecord::Base

  ROLE_DESCONHECIDO = 1
  ROLE_COORDENACAO = 2
  ROLE_SECRETARIA = 3
  ROLE_PROFESSOR = 4
  ROLE_ALUNO = 5
  ROLE_ADMINISTRADOR = 6
end
