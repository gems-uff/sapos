# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Matriz de campos (spec/support/field_matrix.rb), os demais perfis: o papel
# desconhecido, o usuário de dois papéis atuando em cada um, e o aluno.
RSpec.describe "Matriz de campos: demais perfis", type: :request do
  it_behaves_like "matriz de campos", "matriz_campos_demais",
    ["desconhecido", "professor e coordenador, atuando como coordenação",
     "professor e coordenador, atuando como professor", "aluno", "aluno sem aluno vinculado"]
end
