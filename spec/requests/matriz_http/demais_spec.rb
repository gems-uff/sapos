# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Matriz de permissões pelas rotas (spec/support/http_matrix.rb), o usuário
# com dois papéis em cada um deles, e o aluno com e sem aluno vinculado.
RSpec.describe "Matriz HTTP: dois papéis e aluno", type: :request do
  it_behaves_like "matriz HTTP", "matriz_http_demais",
    ["professor e coordenador, atuando como coordenação", "professor e coordenador, atuando como professor",
     "aluno", "aluno sem aluno vinculado"]
end
