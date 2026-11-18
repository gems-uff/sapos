# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require Rails.root.join("db/migrate/20260923120000_filter_accreditation_validity_in_seeded_queries.rb")

# A migration roda uma vez, no deploy, sobre as consultas que cada instalação
# gravou, e nenhum outro ponto da suíte a executa. O job test do CI roda em
# MariaDB: é aqui que o SQL dela encontra o banco de produção.
#
# Foi assim que se pegou o filtro de report_unreached escrito com a coluna
# crua, where("sql LIKE ?"): SQL é palavra reservada no MariaDB, a consulta dava
# erro de sintaxe e o db:migrate abortava em toda instalação -- no SQLite,
# verde. Sem DDL transacional, as reescritas feitas antes do erro ficavam
# gravadas sem a versão registrada, e a nova tentativa tomava as consultas do
# seed por personalizadas.
RSpec.describe FilterAccreditationValidityInSeededQueries do
  # Insere sem passar pelo Query#ensure_valid_params, que executaria o SQL: o
  # que a migration lê e reescreve é o texto.
  def gravar(name, sql)
    Query.insert_all!([{ name: name, sql: sql, created_at: Time.current, updated_at: Time.current }])
    Query.find_by!(name: name)
  end

  def migrar
    migration = described_class.new
    migration.verbose = true
    original = $stdout
    $stdout = StringIO.new
    migration.up
    $stdout.string
  ensure
    $stdout = original
  end

  it "reescreve a consulta do seed e lista só a própria que lê advisement_authorizations" do
    seed = gravar(described_class::ACCREDITED_PROFESSORS, described_class::ACCREDITED_PROFESSORS_OLD)
    propria = gravar("Credenciados da instalação", "SELECT COUNT(*) FROM advisement_authorizations")
    alheia = gravar("Sem credenciamento", "SELECT COUNT(*) FROM professors")

    saida = migrar

    expect(seed.reload.sql).to eq(described_class::ACCREDITED_PROFESSORS_NEW)
    expect(propria.reload.sql).to eq("SELECT COUNT(*) FROM advisement_authorizations")
    expect(saida).to include("Consulta ##{propria.id} ")
    expect(saida).not_to include("Consulta ##{seed.id} ")
    expect(saida).not_to include("Consulta ##{alheia.id} ")
  end

  it "lista uma vez, sem reescrever, a consulta do seed personalizada pela tela" do
    personalizada = gravar(described_class::ACCREDITED_PROFESSORS,
      described_class::ACCREDITED_PROFESSORS_OLD.sub("ORDER BY p.name", "ORDER BY p.email"))

    saida = migrar

    expect(personalizada.reload.sql).to include("ORDER BY p.email")
    expect(saida.scan("Consulta ##{personalizada.id} ").size).to eq(1)
  end
end
