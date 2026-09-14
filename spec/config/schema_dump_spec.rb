# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# db/schema.rb tem de ser o que o dumper do Rails EM USO produz, e nao um arquivo
# editado a mao. O salto para o 8.1 mostrou o risco: o dumper passou a ordenar as
# colunas em ordem alfabetica, o commit so trocou o marcador `Schema[8.1]`, e a
# proxima migration traria ~770 linhas de reordenacao por cima da mudanca real,
# escondendo-a. Este exemplo acusa isso antes do commit.
#
# Duas concessoes, as duas explicadas no AGENTS.md ("Monkey-patches"):
# - so em SQLite, porque o arquivo versionado e dump de SQLite (neutro de
#   adaptador) e o de MariaDB acrescenta `charset:` e `collation:` por tabela;
# - sem as linhas de add_foreign_key, porque o schema_plus_alternative.rb torna
#   add_foreign_key no-op, o banco de teste nao tem chave nenhuma e o dump sai
#   sem elas -- o bloco versionado e reposto a mao a cada regeneracao.
if ActiveRecord::Base.connection.adapter_name == "SQLite"
  RSpec.describe "db/schema.rb" do
    def comparavel(texto)
      texto.lines.reject { |l| l.start_with?("  add_foreign_key ") || l.strip.empty? }.join
    end

    it "e o dump que o Rails em uso produz, a menos das chaves estrangeiras" do
      io = StringIO.new
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, io)
      versionado = File.read(Rails.root.join("db", "schema.rb"))

      expect(comparavel(versionado)).to eq(comparavel(io.string))
    end
  end
end
