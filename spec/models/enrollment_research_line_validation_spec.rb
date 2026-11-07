# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Enrollment#verify_research_line (um validate) preenche a area de pesquisa a
# partir da linha quando a area esta vazia -- mas com self.update, que grava.
# Entao perguntar se uma matricula nova e valida ja a salva no banco.
RSpec.describe Enrollment, "linha de pesquisa sem area", type: :model do
  before(:each) do
    @linha = FactoryBot.create(:research_line)
    @matricula = FactoryBot.build(:enrollment, research_line: @linha, research_area: nil)
  end

  # Controle: a area vem da linha, antes e depois do conserto.
  it "preenche a area a partir da linha" do
    @matricula.valid?

    expect(@matricula.research_area).to eq(@linha.research_area)
  end

  it "nao grava a matricula nova so por validar", pending: "issue #726" do
    @matricula.valid?

    expect(@matricula).not_to be_persisted
  end
end
