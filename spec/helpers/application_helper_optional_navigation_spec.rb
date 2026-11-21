# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

# optional_navigation engole o NoMethodError do render_navigation -- o menu de
# config/navigation.rb chama path helpers e can?, que faltam em alguns
# contextos de view. O rescue nunca rodava na suite (#720).
RSpec.describe ApplicationHelper, type: :helper do
  describe "optional_navigation" do
    it "devolve o menu renderizado" do
      allow(helper).to receive(:render_navigation).with({ level: 1 }).and_return("<ul>menu</ul>")

      expect(helper.optional_navigation({ level: 1 })).to eq("<ul>menu</ul>")
    end

    it "devolve vazio quando o menu chama metodo que nao existe na view" do
      allow(helper).to receive(:render_navigation).and_raise(NoMethodError)

      expect(helper.optional_navigation({ level: 1 })).to eq("")
    end

    it "deixa passar outros erros" do
      allow(helper).to receive(:render_navigation).and_raise(ArgumentError)

      expect { helper.optional_navigation({ level: 1 }) }.to raise_error(ArgumentError)
    end
  end
end
