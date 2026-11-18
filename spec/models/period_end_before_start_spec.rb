# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Periodo com fim antes do inicio (issue #769): Afiliacao e Conceito CAPES nao
# conferem a ordem das datas, como Credenciamento e Bolsa conferem.
RSpec.describe "Fim antes do inicio", type: :model do
  let(:inicio) { Date.new(2024, 6, 1) }
  let(:fim) { Date.new(2024, 1, 1) }

  it "controle: credenciamento recusa" do
    expect(FactoryBot.build(:advisement_authorization, start_date: inicio, end_date: fim)).not_to be_valid
  end

  it "controle: afiliacao com fim depois do inicio e valida" do
    expect(FactoryBot.build(:affiliation, start_date: fim, end_date: inicio)).to be_valid
  end

  it "afiliacao recusa", pending: "issue #769" do
    expect(FactoryBot.build(:affiliation, start_date: inicio, end_date: fim)).not_to be_valid
  end

  it "conceito CAPES recusa", pending: "issue #769" do
    expect(FactoryBot.build(:program_level, start_date: inicio, end_date: fim)).not_to be_valid
  end
end
