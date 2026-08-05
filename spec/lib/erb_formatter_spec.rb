# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ErbFormatter, type: :model do
  # Erb templates cannot be created anymore, but the ones that already exist
  # read the same data and are printed and delivered through the same path, so
  # they escape it the same way. See spec/lib/liquid_formatter_spec.rb.
  let(:data) do
    {
      nome: "Fulano <fulano@uff.br>",
      columns: ["titulo"],
      rows: [["O uso de <strong>"]]
    }
  end
  let(:formatter) { ErbFormatter.new(data) }

  it "renders the data as it is written without an escape" do
    expect(formatter.format("<%= var(:nome) %>"))
      .to eq("Fulano <fulano@uff.br>")
  end

  it "escapes the data for an html destination" do
    expect(formatter.format("<%= var(:nome) %>", escape_data: :html))
      .to eq("Fulano &lt;fulano@uff.br&gt;")
  end

  it "escapes the data for a pdf destination" do
    expect(formatter.format("<%= var(:nome) %>", escape_data: :pdf))
      .to eq("Fulano &lt;fulano@uff.br&gt;")
  end

  it "keeps an apostrophe for a pdf destination" do
    formatter = ErbFormatter.new({ nome: "Sant'Anna" })
    expect(formatter.format("<%= var(:nome) %>", escape_data: :pdf))
      .to eq("Sant'Anna")
  end

  it "leaves the markup of the template untouched" do
    expect(formatter.format("<strong>Aviso</strong>", escape_data: :html))
      .to eq("<strong>Aviso</strong>")
  end

  it "escapes the data of the records built from the query" do
    template = "<% records.each do |r| %><%= r[\"titulo\"] %><% end %>"
    expect(formatter.format(template, escape_data: :html))
      .to eq("O uso de &lt;strong&gt;")
  end

  it "keeps the names of the columns as they are" do
    template = "<% records.each do |r| %><%= r.keys.join %><% end %>"
    expect(formatter.format(template, escape_data: :html)).to eq("titulo")
  end

  it "does not carry the escape of a body into the next render" do
    # the same formatter renders the recipient, the subject and the body
    template = "<% records.each do |r| %><%= r[\"titulo\"] %><% end %>"
    formatter.format(template, escape_data: :html)
    expect(formatter.format(template)).to eq("O uso de <strong>")
  end
end
