# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Matriz de campos (spec/support/field_matrix.rb), os papéis de gestão.
RSpec.describe "Matriz de campos: gestão", type: :request do
  it_behaves_like "matriz de campos", "matriz_campos_gestao",
    ["administrador", "coordenacao", "secretaria"]
end
