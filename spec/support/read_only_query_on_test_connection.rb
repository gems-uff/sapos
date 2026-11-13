# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Em MariaDB, Query.run_read_only_query abre um cliente Mysql2 proprio, que nao
# enxerga o dado nao commitado do exemplo (ver "Pontos cegos da suite" no
# AGENTS.md): declaracao e documento assinado gerados de dado criado no proprio
# exemplo saem vazios no CI e passam em SQLite. Este contexto roda a consulta na
# conexao do teste, como o ramo SQLite ja faz. O ramo Mysql2 de verdade e
# coberto por spec/models/query_spec.rb.
RSpec.shared_context "consulta somente-leitura na conexao do teste" do
  before(:each) do
    allow(Query).to receive(:run_read_only_query) do |sql|
      resultado = ApplicationRecord.connection.exec_query(sql)
      { columns: resultado.columns, rows: resultado.rows }
    end
  end
end
