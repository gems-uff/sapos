# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Grupos de perfis e menus em spec/support/http_matrix.rb (GRUPOS e MENUS).
RSpec.describe "Matriz HTTP: professores, menu Localidades", type: :request do
  it_behaves_like "matriz HTTP", "professores", "localidades"
end
