# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Matriz de campos (spec/support/field_matrix.rb), o professor nas três
# configurações de lançamento de nota e sem professor vinculado.
RSpec.describe "Matriz de campos: professores", type: :request do
  it_behaves_like "matriz de campos", "matriz_campos_professores",
    ["professor (sem lançamento de nota)", "professor (nota no semestre corrente)",
     "professor (nota em todo semestre)", "professor sem professor vinculado"]
end
