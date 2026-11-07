# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# A nota de reprovacao por falta tem de ficar abaixo da nota minima de
# aprovacao. CustomVariable#check_constraints_between_variables acusa o
# conflito com errors.add(:value, :chave, { ... }) -- as opcoes como Hash
# posicional, que o ActiveModel atual recusa com ArgumentError. Em vez da
# mensagem no campo, quem salva o valor em conflito recebe 500.
RSpec.describe CustomVariable, "notas de aprovacao e de reprovacao por falta", type: :model do
  # Controle: valor sem conflito com o padrao de 6,0 e aceito.
  it "aceita reprovacao por falta abaixo da nota minima" do
    variavel = CustomVariable.new(variable: "grade_of_disapproval_for_absence", value: "5.0")

    expect(variavel).to be_valid
  end

  it "recusa reprovacao por falta igual a nota minima, com mensagem", pending: "issue #735" do
    variavel = CustomVariable.new(variable: "grade_of_disapproval_for_absence", value: "6.0")

    expect(variavel).not_to be_valid
    expect(variavel.errors[:value]).to be_present
  end

  it "recusa nota minima igual a reprovacao por falta, com mensagem", pending: "issue #735" do
    CustomVariable.create!(variable: "grade_of_disapproval_for_absence", value: "5.0")
    variavel = CustomVariable.new(variable: "minimum_grade_for_approval", value: "5.0")

    expect(variavel).not_to be_valid
    expect(variavel.errors[:value]).to be_present
  end
end
