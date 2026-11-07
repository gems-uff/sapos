# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

# add_width reparte entre as colunas indicadas a largura que sobra no PDF
# curto. O resto da divisao, um ponto por coluna a partir da primeira, so
# aparecia quando a sobra nao dividia certo -- caso que nenhum relatorio da
# suite produzia (#720).
RSpec.describe Admissions::AdmissionProcessesPdfHelper, type: :helper do
  describe "add_width" do
    it "reparte a sobra igualmente quando a divisao e exata" do
      widths = [10, 20, 30]
      helper.add_width(9, [0, 1, 2], widths)

      expect(widths).to eq([13, 23, 33])
    end

    it "da um ponto a mais as primeiras colunas quando a divisao deixa resto" do
      widths = [10, 20, 30, 40]
      helper.add_width(11, [0, 2, 3], widths)

      expect(widths).to eq([14, 20, 34, 43])
    end
  end
end
