# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# lib/tasks/javascript.rake
#
# Confere se o `node_modules` versionado ainda reflete o que o `package.json` e
# o `yarn.lock` declaram. A pasta e versionada de proposito: o
# `config/initializers/assets.rb` poe `node_modules` no asset load path do
# Sprockets, e e de la que o `application.js` carrega o CodeMirror. Nenhum guia
# de instalacao pede node ou yarn -- quem instala so faz `bundle install` e
# `assets:precompile`, e a pasta commitada e o que sustenta isso.
#
# O preco desse arranjo e que nada obriga quem sobe a versao no `package.json` a
# rodar o `yarn install` e commitar a pasta nova. Ja aconteceu: o lock anunciava
# uma versao e o que compilava era outra, duas atras. Esta task e a guarda.
#
# Nao precisa de node, de rede nem de banco: le quatro arquivos que ja vem no
# `git clone`. A aritmetica de semver e dispensavel porque a invariante do yarn
# basta -- a faixa declarada no `package.json` tem de ser a chave da entrada do
# `yarn.lock`, e a `version` dessa entrada tem de ser a do pacote instalado.
namespace :javascript do
  desc "Confere se o node_modules versionado casa com o package.json e o yarn.lock"
  task :check do
    require "json"

    raiz = File.expand_path("../..", __dir__)
    caminho_package = File.join(raiz, "package.json")
    caminho_lock = File.join(raiz, "yarn.lock")
    caminho_integrity = File.join(raiz, "node_modules", ".yarn-integrity")

    problemas = []

    # `name@faixa` => versao resolvida. O formato v1 do yarn.lock poe a chave na
    # coluna zero, aceita varias separadas por virgula e as aspeia quando o nome
    # tem escopo (`"@babel/core@^7.0.0"`).
    versoes_do_lock = {}
    chaves_correntes = []
    File.foreach(caminho_lock) do |linha|
      next if linha.start_with?("#") || linha.strip.empty?
      if linha.start_with?(/\S/)
        chaves_correntes = linha.strip.chomp(":").split(",").map do |chave|
          chave.strip.delete_prefix('"').delete_suffix('"')
        end
      elsif (casou = linha.match(/\A\s+version\s+"([^"]+)"/))
        chaves_correntes.each { |chave| versoes_do_lock[chave] = casou[1] }
      end
    end

    package = JSON.parse(File.read(caminho_package))
    declaradas = package.fetch("dependencies", {}).merge(package.fetch("devDependencies", {}))

    declaradas.each do |nome, faixa|
      padrao = "#{nome}@#{faixa}"
      resolvida = versoes_do_lock[padrao]

      if resolvida.nil?
        problemas << "#{nome}: o package.json pede #{faixa}, mas o yarn.lock nao " \
                     "tem entrada para #{padrao}. O lock ficou para tras."
        next
      end

      manifesto_instalado = File.join(raiz, "node_modules", nome, "package.json")
      unless File.exist?(manifesto_instalado)
        problemas << "#{nome}: declarado no package.json, mas node_modules/#{nome} " \
                     "nao esta na arvore."
        next
      end

      instalada = JSON.parse(File.read(manifesto_instalado))["version"]
      if instalada != resolvida
        problemas << "#{nome}: o yarn.lock resolve #{resolvida} e a pasta " \
                     "versionada tem #{instalada}."
      end
    end

    # Pacote na arvore que ninguem declarou. O `_` cobre o `.bin` e afins.
    diretorio_modules = File.join(raiz, "node_modules")
    if Dir.exist?(diretorio_modules)
      instalados = Dir.children(diretorio_modules).reject { |nome| nome.start_with?(".") }
      escopados = instalados.select { |nome| nome.start_with?("@") }
      instalados -= escopados
      escopados.each do |escopo|
        Dir.children(File.join(diretorio_modules, escopo)).each do |nome|
          instalados << "#{escopo}/#{nome}"
        end
      end
      (instalados - declaradas.keys).sort.each do |nome|
        problemas << "#{nome}: esta em node_modules mas nao e declarado no package.json."
      end
    end

    # Conferencia secundaria pelo registro que o proprio yarn mantem do que
    # produziu esta pasta. O `systemParams` fica de fora de proposito: ele varia
    # com a maquina de quem rodou o yarn install e nao diz nada sobre versao.
    if File.exist?(caminho_integrity)
      integrity = JSON.parse(File.read(caminho_integrity))
      esperados = declaradas.map { |nome, faixa| "#{nome}@#{faixa}" }.sort
      registrados = Array(integrity["topLevelPatterns"]).sort
      if registrados != esperados
        problemas << ".yarn-integrity registra #{registrados.inspect}, mas o " \
                     "package.json declara #{esperados.inspect}."
      end
    end

    if problemas.empty?
      puts "✅ node_modules, package.json e yarn.lock concordam."
    else
      puts "❌ O node_modules versionado divergiu dos manifestos:\n\n"
      problemas.each { |problema| puts "  - #{problema}" }
      puts "\nRode `yarn install` e commite o que mudar em node_modules/ " \
           "(inclusive o .yarn-integrity). A pasta e versionada de proposito: " \
           "veja o cabecalho de lib/tasks/javascript.rake."
      exit 1
    end
  end
end
