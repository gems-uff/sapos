# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe PdfHelper, type: :helper do
  # The toolbar of the template editor is shared by notifications and
  # assertions. These specs pin down how its markup reaches the PDF, so that a
  # change made for the email side cannot break the assertions.
  describe "parse_align_segments" do
    it "returns a single segment with the default alignment" do
      expect(helper.parse_align_segments("Declaramos que")).to eq(
        [{ align: :justify, text: "Declaramos que" }]
      )
    end

    it "honors the given default alignment" do
      expect(helper.parse_align_segments("Declaramos que", :left)).to eq(
        [{ align: :left, text: "Declaramos que" }]
      )
    end

    it "reads the alignment of a div produced by the align tag" do
      text = "<div style=\"text-align: center;\">Centralizado</div>"
      expect(helper.parse_align_segments(text)).to eq(
        [{ align: :center, text: "Centralizado" }]
      )
    end

    it "keeps the text around an aligned block" do
      text = "antes\n<div style=\"text-align: right;\">meio</div>depois"
      expect(helper.parse_align_segments(text)).to eq(
        [
          { align: :justify, text: "antes\n" },
          { align: :right, text: "meio" },
          { align: :justify, text: "depois" }
        ]
      )
    end

    it "reads every alignment of the toolbar" do
      [:left, :center, :right, :justify].each do |align|
        text = "<div style=\"text-align: #{align};\">a</div>"
        expect(helper.parse_align_segments(text)).to eq(
          [{ align: align, text: "a" }]
        )
      end
    end

    it "reads more than one aligned block" do
      text = "<div style=\"text-align: left;\">a</div>" \
        "<div style=\"text-align: right;\">b</div>"
      expect(helper.parse_align_segments(text)).to eq(
        [{ align: :left, text: "a" }, { align: :right, text: "b" }]
      )
    end

    it "handles an empty text" do
      expect(helper.parse_align_segments(nil)).to eq(
        [{ align: :justify, text: "" }]
      )
      expect(helper.parse_align_segments("")).to eq([])
    end
  end

  describe "the markup that prawn renders" do
    # The bold and italic buttons of the toolbar write <strong> and <em>, and
    # the PDF is printed with inline_format, so prawn has to understand them.
    it "renders strong as bold" do
      expect(Prawn::Text::Formatted::Parser.format("<strong>a</strong>"))
        .to match([hash_including(text: "a", styles: [:bold])])
    end

    it "renders em as italic" do
      expect(Prawn::Text::Formatted::Parser.format("<em>a</em>"))
        .to match([hash_including(text: "a", styles: [:italic])])
    end
  end

  describe "escape_inline_format" do
    def printed(text)
      Prawn::Text::Formatted::Parser
        .format(helper.escape_inline_format(text))
        .map { |fragment| fragment[:text] }.join
    end

    it "prints an address written between angle brackets" do
      expect(printed("Fulano <fulano@uff.br>")).to eq("Fulano <fulano@uff.br>")
    end

    it "prints a comparison" do
      expect(printed("CR < 7 e P&D")).to eq("CR < 7 e P&D")
    end

    it "keeps the markup of the toolbar" do
      expect(helper.escape_inline_format("<strong>a</strong> <em>b</em>"))
        .to eq("<strong>a</strong> <em>b</em>")
    end

    it "keeps the other tags that prawn understands" do
      [
        "<b>a</b>", "<i>a</i>", "<u>a</u>", "<sub>a</sub>", "<sup>a</sup>",
        "<strikethrough>a</strikethrough>", "<br>", "<br/>",
        "<color rgb=\"FF0000\">a</color>", "<font size=\"14\">a</font>",
        "<link href=\"http://uff.br\">a</link>"
      ].each do |markup|
        expect(helper.escape_inline_format(markup)).to eq(markup)
      end
    end

    it "escapes a tag that prawn does not understand" do
      expect(helper.escape_inline_format("<script>a</script>"))
        .to eq("&lt;script>a&lt;/script>")
    end

    it "keeps an entity that was already written in the template" do
      expect(helper.escape_inline_format("a &lt; b")).to eq("a &lt; b")
    end

    it "handles an empty text" do
      expect(helper.escape_inline_format(nil)).to eq("")
      expect(helper.escape_inline_format("")).to eq("")
    end
  end

  describe "print_multipage_text_with_alignments" do
    let(:pdf) { Prawn::Document.new }

    # Reads back what was printed. Prawn writes the text of a page as hex
    # strings, and it may break a word into more than one of them.
    def printed_pages(document)
      document.render
      document.state.pages.map do |page|
        page.content.stream.filtered_stream
          .scan(/<([0-9a-fA-F]+)>/)
          .map { |hex| [hex[0]].pack("H*") }.join
      end
    end

    context "a text that does not fit in a single page" do
      let(:words) { (1..120).map { |i| format("w%03d", i) } }

      def print_and_read(text)
        helper.print_multipage_text_with_alignments(pdf, text, 400, 80)
        printed_pages(pdf).join
      end

      it "prints every word of a long text" do
        printed = print_and_read(words.join(" "))
        expect(pdf.page_count).to be > 1
        expect(words.reject { |word| printed.include?(word) }).to be_empty
      end

      it "prints every word when the markup is in the text of the next page" do
        text = "#{words[0..99].join(' ')} <strong>#{words[100]}</strong> " \
          "#{words[101..].join(' ')}"
        printed = print_and_read(text)
        expect(words.reject { |word| printed.include?(word) }).to be_empty
      end

      it "prints every word when an entity is in the text of the next page" do
        text = "#{words[0..99].join(' ')} a &lt; b #{words[100..].join(' ')}"
        printed = print_and_read(text)
        expect(words.reject { |word| printed.include?(word) }).to be_empty
      end

      it "keeps the markup of a text that is printed on the next page" do
        text = "#{words[0..99].join(' ')} <strong>NEGRITO</strong> " \
          "#{words[101..].join(' ')}"
        helper.print_multipage_text_with_alignments(pdf, text, 400, 80)
        pages = printed_pages(pdf)
        page_with_markup = pages.index { |page| page.include?("NEGRITO") }
        expect(page_with_markup).to be > 0
        fonts = pdf.state.pages[page_with_markup]
          .content.stream.filtered_stream.scan(%r{/F[0-9.]+}).uniq
        expect(fonts.size).to be > 1
      end
    end

    it "prints a text with the markup of the toolbar" do
      text = "Declaramos que\n" \
        "<div style=\"text-align: center;\"><strong>Fulano</strong></div>\n" \
        "esteve presente."
      expect do
        helper.print_multipage_text_with_alignments(pdf, text, 500, 560)
      end.not_to raise_error
    end

    it "prints a text without any markup" do
      expect do
        helper.print_multipage_text_with_alignments(pdf, "Declaramos", 500, 560)
      end.not_to raise_error
    end

    it "prints data that looks like markup" do
      text = "Fulano <fulano@uff.br> tem CR < 7"
      expect do
        helper.print_multipage_text_with_alignments(pdf, text, 500, 560)
      end.not_to raise_error
    end
  end
end
