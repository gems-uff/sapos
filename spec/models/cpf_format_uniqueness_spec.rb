# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O CPF e gravado como foi digitado e a unicidade compara o texto: o mesmo CPF
# com e sem pontuacao passa por dois, e a mesma pessoa fica com duas fichas.
# As reproducoes ficam pending ate a issue #674 definir a forma unica de gravar
# o CPF; quando o conserto chegar, o RSpec acusa o pending que passou, e e a
# hora de tirar a marca. O controle nao e pending: e ele que prova que o
# cenario monta e que a recusa por CPF repetido funciona.
#
# O espaco fica no comeco do valor de proposito: a collation de producao ignora
# o espaco do fim, e o exemplo passaria em MariaDB sem conserto nenhum.
RSpec.describe "Unicidade do CPF escrito de formas diferentes", type: :model do
  { student: "aluno", professor: "professor" }.each do |factory, papel|
    describe "na ficha de #{papel}" do
      before(:each) { FactoryBot.create(factory, cpf: "529.982.247-25") }

      it "recusa o CPF escrito do mesmo jeito" do
        repetido = FactoryBot.build(factory, cpf: "529.982.247-25")
        expect(repetido).to be_invalid
        expect(repetido.errors).to be_of_kind(:cpf, :taken)
      end

      it "recusa o CPF escrito só com os dígitos", pending: "issue #674" do
        repetido = FactoryBot.build(factory, cpf: "52998224725")
        expect(repetido).to be_invalid
        expect(repetido.errors).to be_of_kind(:cpf, :taken)
      end

      it "recusa o CPF com espaço antes", pending: "issue #674" do
        repetido = FactoryBot.build(factory, cpf: " 529.982.247-25")
        expect(repetido).to be_invalid
        expect(repetido.errors).to be_of_kind(:cpf, :taken)
      end
    end
  end
end
