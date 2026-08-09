# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe LiquidFormatter, type: :model do
  # A template mixes markup written by its author with data that comes from a
  # query. Only the author writes markup, so the data is escaped while the
  # template is rendered and the two are told apart by where they come from.
  def render(template, data = {}, **options)
    LiquidFormatter.new(data).format(template, **options)
  end

  describe "a template rendered without an escape" do
    it "renders the data as it is written" do
      expect(render("{{ d }}", { "d" => "Fulano <fulano@uff.br>" }))
        .to eq("Fulano <fulano@uff.br>")
    end
  end

  describe "a template rendered for an html destination" do
    it "escapes data that looks like markup" do
      expect(render("{{ d }}", { "d" => "<strong>x</strong>" }, escape_data: :html))
        .to eq("&lt;strong&gt;x&lt;/strong&gt;")
    end

    it "escapes the quotes, because data may fill an attribute" do
      expect(render("{{ d }}", { "d" => "a \"b\" 'c'" }, escape_data: :html))
        .to eq("a &quot;b&quot; &#39;c&#39;")
    end

    it "keeps the markup that the template wrote around the data" do
      expect(
        render("<strong>{{ d }}</strong>", { "d" => "<em>x</em>" }, escape_data: :html)
      ).to eq("<strong>&lt;em&gt;x&lt;/em&gt;</strong>")
    end
  end

  describe "a template rendered for a pdf destination" do
    it "escapes data that looks like markup" do
      expect(render("{{ d }}", { "d" => "<strong>x</strong>" }, escape_data: :pdf))
        .to eq("&lt;strong&gt;x&lt;/strong&gt;")
    end

    it "escapes the ampersand before the angle brackets" do
      expect(render("{{ d }}", { "d" => "P&D < Q" }, escape_data: :pdf))
        .to eq("P&amp;D &lt; Q")
    end

    it "keeps a quote and an apostrophe, which prawn does not read back" do
      expect(render("{{ d }}", { "d" => "Sant'Anna disse \"ok\"" }, escape_data: :pdf))
        .to eq("Sant'Anna disse \"ok\"")
    end
  end

  describe "what the escape does not reach" do
    it "leaves the markup of the template untouched" do
      expect(render("<strong>Aviso</strong>", {}, escape_data: :html))
        .to eq("<strong>Aviso</strong>")
    end

    it "leaves the div of the align tag untouched" do
      expect(render("{% align center %}a{% endalign %}", {}, escape_data: :html))
        .to eq("<div style=\"text-align: center;\">a</div>")
    end

    it "escapes the data inside an aligned block" do
      expect(
        render("{% align center %}{{ d }}{% endalign %}", { "d" => "<i>x</i>" },
               escape_data: :html)
      ).to eq("<div style=\"text-align: center;\">&lt;i&gt;x&lt;/i&gt;</div>")
    end
  end

  describe "the output that liquid produces" do
    it "applies a filter to the data before the escape" do
      # the filter reads the data, not the escape of the data
      expect(render("{{ d | size }}", { "d" => "<>" }, escape_data: :html))
        .to eq("2")
    end

    it "compares the data before the escape" do
      expect(
        render("{% if d == '<a>' %}sim{% else %}nao{% endif %}",
               { "d" => "<a>" }, escape_data: :html)
      ).to eq("sim")
    end

    it "joins an array the same way it does without the escape" do
      data = { "d" => ["a", "<b>"] }
      expect(render("{{ d }}", data, escape_data: :html)).to eq("a&lt;b&gt;")
      expect(render("{{ d }}", data)).to eq("a<b>")
    end

    it "renders a variable that does not exist as an empty text" do
      expect(render("[{{ inexistente }}]", {}, escape_data: :html)).to eq("[]")
    end

    it "escapes the data of the records built from the query" do
      data = { columns: ["nome"], rows: [["<i>x</i>"]] }
      expect(
        render("{% for r in records %}{{ r.nome }}{% endfor %}", data,
               escape_data: :html)
      ).to eq("&lt;i&gt;x&lt;/i&gt;")
    end
  end
end
