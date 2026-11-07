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
  # Os filtros e tags que o SAPOS registra sobre o Liquid (#720). Eles usam
  # interno da gem -- Liquid::StandardFilters::InputIterator, Liquid::Utils,
  # Liquid::Tag e Liquid::Block --, e os templates que os chamam sao os que cada
  # instalacao escreveu pela tela, que a suite nao conhece.
  describe "as extensoes do SAPOS" do
    let(:data) { Date.new(2026, 3, 10) }

    it "localiza uma data pelo formato padrao" do
      expect(render("{{ d | localize }}", { "d" => data }))
        .to eq(I18n.localize(data.to_time, format: :default))
    end

    it "localiza pelo atalho l, com formato" do
      expect(render("{{ d | l: 'short' }}", { "d" => data }))
        .to eq(I18n.localize(data.to_time, format: :short))
    end

    it "localiza uma data escrita como texto" do
      expect(render("{{ '2026-03-10' | localize }}"))
        .to eq(I18n.localize(Time.zone.parse("2026-03-10"), format: :default))
    end

    it "tira a media" do
      expect(render("{{ n | avg }}", { "n" => [7, 8, 9] })).to eq("8.0")
    end

    it "tira a media de uma coluna dos registros, convertendo o texto" do
      expect(render("{{ records | avg: 'nota' }}", { columns: ["nota"], rows: [["7"], ["8.5"]] }))
        .to eq("7.75")
    end

    it "tira a mediana de quantidade par e impar" do
      expect(render("{{ n | median }}", { "n" => [3, 1, 2, 10] })).to eq("2.5")
      expect(render("{{ n | median }}", { "n" => [5, 1, 3] })).to eq("3.0")
    end

    it "traduz propriedade invalida em erro do Liquid, sem derrubar a renderizacao" do
      expect(render("{{ n | avg: 'x' }}", { "n" => [7, 8] }))
        .to eq("Liquid error: cannot select the property 'x'")
    end

    it "lista os e-mails de quem tem o papel" do
      papel = FactoryBot.create(:role_secretaria)
      create_confirmed_user([papel], "sec1@ic.uff.br", "Sec Um")
      create_confirmed_user([papel], "sec2@ic.uff.br", "Sec Dois")

      expect(render("{% emails #{papel.name} %}").split(";"))
        .to contain_exactly("sec1@ic.uff.br", "sec2@ic.uff.br")
    end

    it "troca o idioma dentro do bloco e volta depois" do
      saida = render("{% language en %}{{ d | l: 'long' }}{% endlanguage %}|{{ d | l: 'long' }}", { "d" => data })

      expect(saida).to eq(
        "#{I18n.with_locale(:en) { I18n.localize(data.to_time, format: :long) }}|" \
        "#{I18n.localize(data.to_time, format: :long)}"
      )
      expect(I18n.locale).to eq(:"pt-BR")
    end

    it "alinha com justificado quando o bloco nao diz" do
      expect(render("{% align %}x{% endalign %}"))
        .to eq('<div style="text-align: justify;">x</div>')
    end
  end
end
