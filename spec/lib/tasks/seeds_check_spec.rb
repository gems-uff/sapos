# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O SQL das consultas so executa quando os seeds rodam: Query#ensure_valid_params
# e um `validate` que roda a consulta, e o `save!` do seed a submete ao banco.
# Como a suite nunca semeia, migration que renomeia ou derruba coluna passava
# batida por ela -- e o estrago so aparecia quando alguem abrisse o relatorio.
#
# Este exemplo fecha esse vao chamando `rake seeds:check`, que carrega esquema e
# seeds num banco DESCARTAVEL (nunca o de teste nem o de desenvolvimento). Custa
# alguns segundos e e o mesmo comando que o job `seed` do CI roda em MariaDB.
RSpec.describe "seeds:check", type: :task do
  it "carrega num banco limpo, executando o SQL de todas as consultas" do
    saida = nil
    ok = nil

    Dir.chdir(Rails.root) do
      # Sem SEED_CHECK_DATABASE_URL a task cria um SQLite descartavel proprio.
      # DATABASE_URL vai limpo para nao arrastar o banco desta suite.
      env = { "SEED_CHECK_DATABASE_URL" => nil, "DATABASE_URL" => nil }
      saida = IO.popen(env, ["bundle", "exec", "rake", "seeds:check"], err: [:child, :out], &:read)
      ok = $?.success?
    end

    # A mensagem do RecordInvalid nomeia a coluna que sumiu; leve-a inteira para
    # a falha, senao o diagnostico fica no terminal de quem rodou e some.
    expect(ok).to be(true), "rake seeds:check falhou:\n#{saida}"
  end
end
