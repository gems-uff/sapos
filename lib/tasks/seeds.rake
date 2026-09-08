# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# lib/tasks/seeds.rake
#
# Carrega o esquema e roda os seeds num banco descartavel. O valor esta em
# `Query#ensure_valid_params`: ele e um `validate` que EXECUTA o SQL, entao
# `query_obj.save!` no seed submete cada consulta ao banco. Rodar os seeds e,
# portanto, o teste de compatibilidade entre o SQL guardado e o esquema --
# migration que renomeia ou derruba coluna quebra aqui, e em nenhum outro lugar
# da suite.
#
# O banco e sempre isolado: a task nunca toca no desenvolvimento nem no banco de
# teste, e por isso roda em subprocesso com DATABASE_URL proprio.
namespace :seeds do
  desc "Carrega esquema e seeds num banco descartavel, validando o SQL das consultas"
  task :check do
    require "tmpdir"
    require "fileutils"

    # Em MariaDB o banco tem de existir de antemao (a task nao cria); em SQLite
    # o arquivo nasce sozinho. O CI aponta esta variavel para o MariaDB, que e
    # onde producao roda -- e onde o bloco `unless is_sqlite` dos seeds carrega.
    url = ENV["SEED_CHECK_DATABASE_URL"]
    descartavel = nil

    if url.nil? || url.empty?
      descartavel = File.join(Dir.tmpdir, "sapos_seeds_check_#{Process.pid}.sqlite3")
      url = "sqlite3:#{descartavel}"
      puts "Banco descartavel: #{descartavel}"
    else
      puts "Banco informado por SEED_CHECK_DATABASE_URL"
    end

    env = { "DATABASE_URL" => url, "RAILS_ENV" => "test" }
    comando = ["bundle", "exec", "rake", "db:schema:load", "db:seed"]

    begin
      ok = system(env, *comando)
      unless ok
        puts "\n❌ Os seeds falharam. Consulta cujo SQL nao casa mais com o " \
             "esquema aparece acima como RecordInvalid, com a coluna no texto."
        exit 1
      end
      puts "\n✅ Esquema e seeds carregados; o SQL de todas as consultas executou."
    ensure
      FileUtils.rm_f(descartavel) if descartavel
    end
  end
end
