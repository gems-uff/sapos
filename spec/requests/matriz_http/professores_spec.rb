# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Matriz de permissões pelas rotas (spec/support/http_matrix.rb), o professor
# nas três configurações de lançamento de nota e sem professor vinculado.
RSpec.describe "Matriz HTTP: professores", type: :request do
  it_behaves_like "matriz HTTP", "matriz_http_professores",
    ["professor (sem lançamento de nota)", "professor (nota no semestre corrente)",
     "professor (nota em todo semestre)", "professor sem professor vinculado"]
end
