# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Apagar a nota minima de aprovacao faz valer o padrao 6,0. Se a nota de
# reprovacao por falta for 6,0 ou mais, a combinacao fica invalida, e o
# before_destroy :validate_destroy deveria barrar a exclusao. Ele devolve
# false, que deixou de interromper o callback no Rails 5 (o certo e
# throw(:abort)).
RSpec.describe CustomVariable, "exclusao da nota minima de aprovacao", type: :model do
  before(:each) do
    @minima = CustomVariable.create!(variable: "minimum_grade_for_approval", value: "7.0")
  end

  # Controle: sem conflito, a exclusao segue, antes e depois do conserto.
  it "apaga quando a nota de reprovacao por falta fica abaixo do padrao" do
    CustomVariable.create!(variable: "grade_of_disapproval_for_absence", value: "5.0")

    @minima.destroy

    expect(CustomVariable.exists?(@minima.id)).to be false
  end

  it "nao apaga quando a nota de reprovacao por falta passaria do padrao", pending: "issue #725" do
    CustomVariable.create!(variable: "grade_of_disapproval_for_absence", value: "6.5")

    @minima.destroy

    expect(CustomVariable.exists?(@minima.id)).to be true
    expect(@minima.errors[:base]).to be_present
  end
end
