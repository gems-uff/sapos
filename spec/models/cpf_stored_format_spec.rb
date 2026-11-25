# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Regra de preenchimento do CPF decidida na issue #674: o que e CPF (11 digitos,
# com ou sem pontuacao) fica gravado de uma forma so, pontuado; o que nao e CPF
# (documento de estrangeiro) fica como foi digitado, sem espaco na borda. Hoje o
# valor e gravado como chega, e as reproducoes ficam pending ate o conserto;
# quando ele chegar, o RSpec acusa o pending que passou, e e a hora de tirar a
# marca. Os controles, sem pending, provam que o cenario monta e fixam o que ja
# vale: o CPF pontuado e o documento sem espaco nao mudam ao gravar.
#
# Cada exemplo le o valor de volta do banco, para nao depender de onde a regra
# for posta (na atribuicao ou na validacao).
RSpec.describe "Forma gravada do CPF", type: :model do
  { student: "aluno", professor: "professor" }.each do |factory, papel|
    describe "na ficha de #{papel}" do
      def gravado(factory, cpf)
        FactoryBot.create(factory, cpf: cpf).reload.cpf
      end

      it "mantém o CPF que chega pontuado" do
        expect(gravado(factory, "529.982.247-25")).to eq("529.982.247-25")
      end

      it "mantém como veio o documento que não é CPF" do
        expect(gravado(factory, "AB123456")).to eq("AB123456")
      end

      it "pontua o CPF digitado só com os dígitos", pending: "issue #674" do
        expect(gravado(factory, "52998224725")).to eq("529.982.247-25")
      end

      it "pontua o CPF digitado com espaço entre os blocos", pending: "issue #674" do
        expect(gravado(factory, "529 982 247 25")).to eq("529.982.247-25")
      end

      it "tira o espaço em volta do CPF", pending: "issue #674" do
        expect(gravado(factory, " 529.982.247-25 ")).to eq("529.982.247-25")
      end

      it "tira o espaço em volta do documento que não é CPF", pending: "issue #674" do
        expect(gravado(factory, " AB123456 ")).to eq("AB123456")
      end
    end
  end
end
