# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

# NumbersHelper#number_with_delimiter sobrescreve o do Rails. Sem format_as, o
# valor que nao e numero volta como veio, como no Rails; esse ramo nunca rodava
# na suite (#720).
RSpec.describe NumbersHelper, type: :helper do
  describe "number_with_delimiter sem format_as" do
    it "devolve intacto o valor que nao e numero" do
      expect(helper.number_with_delimiter("12x34")).to eq("12x34")
    end

    it "devolve nil quando recebe nil" do
      expect(helper.number_with_delimiter(nil)).to be_nil
    end

    # Controle: numero passa pela formatacao com o separador da localidade.
    it "separa os milhares do numero" do
      expect(helper.number_with_delimiter(1234567)).to eq("1.234.567")
    end
  end
end
