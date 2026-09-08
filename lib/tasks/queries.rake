# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# lib/tasks/queries.rake
#
# Confere as consultas GRAVADAS NO BANCO desta instalacao contra o esquema
# atual. E o complemento de `seeds:check`: aquela cobre as consultas que vieram
# do seed, versionadas no repositorio; esta cobre as que a coordenacao criou ou
# editou pela tela, que o repositorio nao conhece e que sao a maioria.
#
# Use antes de aplicar migration que renomeie ou derrube coluna, e de novo
# depois. Consulta quebrada so se manifesta quando alguem abre o relatorio ou a
# notificacao dispara -- pode levar meses.
namespace :queries do
  desc "Executa cada consulta gravada e lista as que nao casam mais com o esquema"
  task check: :environment do
    # `valid?` dispara Query#ensure_valid_params, que EXECUTA o SQL. Nada e
    # gravado: a task nao chama save. As consultas sao SELECT e, havendo
    # configuracao `<env>_read_only`, correm pela conexao somente-leitura.
    total = Query.count
    quebradas = []

    Query.find_each do |query|
      next if query.valid?
      erros = query.errors[:sql]
      next if erros.empty?
      quebradas << [query.id, query.name, erros.join("; ")]
    end

    puts "consultas gravadas: #{total}"

    if quebradas.empty?
      puts "✅ todas executaram contra o esquema atual."
      next
    end

    puts "❌ #{quebradas.size} nao executaram:"
    quebradas.each do |id, name, erro|
      puts "  [#{id}] #{name}"
      puts "        #{erro}"
    end
    # Codigo de saida diferente de zero para servir de porta em script de deploy.
    exit 1
  end
end
