# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Assertion, type: :model do
  describe "associations" do
    it "belongs to a query" do
      assoc = described_class.reflect_on_association(:query)
      expect(assoc.macro).to eq :belongs_to
    end
  end

  describe "to_label" do
    it "returns the name of the assertion" do
      assertion = Assertion.new(name: "Sample Assertion")
      expect(assertion.to_label).to eq "Sample Assertion"
    end
  end
end
