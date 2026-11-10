# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Matriz de permissões pelas rotas (spec/support/http_matrix.rb), papéis de
# gestão. Os perfis se repartem em três arquivos para que os workers do CI
# dividam o custo; o visitante e o desconhecido estão em
# spec/requests/route_authorization_spec.rb.
RSpec.describe "Matriz HTTP: gestão", type: :request do
  it_behaves_like "matriz HTTP", "matriz_http_gestao",
    ["administrador", "coordenacao", "secretaria", "suporte"]
end
