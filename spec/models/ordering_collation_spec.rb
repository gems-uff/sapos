# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Ordenação e LIKE sob a collation de produção — o companheiro de
# spec/models/uniqueness_collation_spec.rb. O AGENTS.md nomeia três pontos cegos
# da suíte em SQLite: unicidade, ordenação e LIKE. O primeiro já estava coberto;
# estes dois não estavam.
#
# A diferença não é sutil: em BINARY (SQLite) "Á" é U+00C1, que vem DEPOIS de
# "Z", então "Bastos" precede "Ávila". Em utf8mb4_unicode_ci "Á" colaciona como
# "A", e a ordem INVERTE. Num sistema em português, com acento em nome de aluno,
# toda lista ordenada por nome sai numa ordem no teste e noutra em produção.
#
# Roda com a skill suite-mariadb ou no CI (que roda em MariaDB).
if ActiveRecord::Base.connection.adapter_name == "Mysql2"
  RSpec.describe "Ordenação sob a collation de produção", type: :model do
    describe "ORDER BY com acento" do
      it "ordena o acentuado pela letra base, não pelo código do caractere" do
        avila = FactoryBot.create(:student, name: "Ávila", cpf: "ord-1")
        bastos = FactoryBot.create(:student, name: "Bastos", cpf: "ord-2")

        nomes = Student.where(id: [avila.id, bastos.id]).order(:name).pluck(:name)

        # Em SQLite esta ordem seria ["Bastos", "Ávila"].
        expect(nomes).to eq(["Ávila", "Bastos"])
      end

      it "intercala acentuado e sem acento na mesma sequência" do
        criados = ["Alves", "Álvaro", "Amaral"].each_with_index.map do |nome, i|
          FactoryBot.create(:student, name: nome, cpf: "ord-mix-#{i}")
        end

        nomes = Student.where(id: criados.map(&:id)).order(:name).pluck(:name)

        # "Álvaro" colaciona como "Alvaro", e "Alva" < "Alve" -- ou seja, ele cai
        # ANTES de "Alves", intercalado com os sem acento em vez de agrupado à
        # parte. Em SQLite viria por último, depois de "Amaral", porque "Á" é
        # U+00C1 e vem depois de "Z".
        expect(nomes).to eq(["Álvaro", "Alves", "Amaral"])
      end
    end

    describe "ORDER BY com maiúscula e minúscula" do
      it "não separa por caixa" do
        criados = ["alves", "Barros", "Cunha"].each_with_index.map do |nome, i|
          FactoryBot.create(:student, name: nome, cpf: "ord-caixa-#{i}")
        end

        nomes = Student.where(id: criados.map(&:id)).order(:name).pluck(:name)

        # Em SQLite as maiúsculas vêm todas antes das minúsculas, e o resultado
        # seria ["Barros", "Cunha", "alves"].
        expect(nomes).to eq(["alves", "Barros", "Cunha"])
      end
    end

    describe "LIKE" do
      it "encontra o nome acentuado a partir da busca sem acento" do
        aluno = FactoryBot.create(:student, name: "Ávila", cpf: "like-1")

        encontrados = Student.where("name LIKE ?", "%avila%").pluck(:id)

        expect(encontrados).to include(aluno.id)
      end

      it "encontra independentemente da caixa" do
        aluno = FactoryBot.create(:student, name: "Conceição", cpf: "like-2")

        encontrados = Student.where("name LIKE ?", "%CONCEICAO%").pluck(:id)

        expect(encontrados).to include(aluno.id)
      end
    end
  end
end
