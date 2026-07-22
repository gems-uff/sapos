# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Assertion, type: :model do
  it { should belong_to(:query).required(true) }


  let(:query) { FactoryBot.build(:query) }
  let(:assertion) do
    Assertion.new(
      name: "Test Assertion",
      assertion_template: "Template",
      query: query
    )
  end
  subject { assertion }

  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:assertion_template).on(:update) }
    it { should validate_numericality_of(:expiration_in_months).only_integer.is_greater_than(0).allow_nil }
  end

  describe "format_text" do
    # The text is printed by prawn with inline_format, so the data that fills
    # the template is escaped for that destination: prawn only reads &lt;,
    # &gt; and &amp; back, and a name has to keep its apostrophe.
    def formatted(template, rows, columns)
      assertion.assertion_template = template
      allow(assertion.query).to receive(:execute).and_return(
        { rows: rows, columns: columns }
      )
      assertion.format_text
    end

    it "escapes data that looks like markup" do
      expect(formatted("Tese: {{ titulo }}", [["O uso de <strong>"]], ["titulo"]))
        .to eq("Tese: O uso de &lt;strong&gt;")
    end

    it "keeps the markup that the template wrote" do
      expect(formatted("<strong>{{ nome }}</strong>", [["Fulano"]], ["nome"]))
        .to eq("<strong>Fulano</strong>")
    end

    it "keeps an apostrophe, which prawn does not read back" do
      expect(formatted("{{ nome }}", [["Sant'Anna"]], ["nome"]))
        .to eq("Sant'Anna")
    end

    it "raises when the query has no result" do
      expect { formatted("{{ nome }}", [], ["nome"]) }
        .to raise_error(Exceptions::EmptyQueryException)
    end
  end
end
