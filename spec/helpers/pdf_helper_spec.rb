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

  describe "the data that a formatter escaped into the markup" do
    # The data is escaped when the template is rendered, so what reaches the
    # PDF is markup. These specs pin down that prawn prints the escaped data
    # back as the characters that were written in the database.
    def printed(text)
      Prawn::Text::Formatted::Parser.format(text)
        .map { |fragment| fragment[:text] }.join
    end

    def rendered(data)
      LiquidFormatter.new({ "data" => data })
        .format("{{ data }}", escape_data: :pdf)
    end

    it "prints an address written between angle brackets" do
      expect(printed(rendered("Fulano <fulano@uff.br>")))
        .to eq("Fulano <fulano@uff.br>")
    end

    it "prints a comparison and an ampersand" do
      expect(printed(rendered("CR < 7 e P&D"))).to eq("CR < 7 e P&D")
    end

    it "prints a title that looks like markup instead of formatting the text" do
      title = "Um estudo sobre o uso de <strong> nos CLAUDE.md"
      expect(printed(rendered(title))).to eq(title)
    end

    it "prints a title that opens and closes a tag" do
      title = "Um estudo sobre <strong> e </strong> em projetos"
      expect(printed(rendered(title))).to eq(title)
    end

    it "prints every character that the escape produces" do
      expect(printed(rendered("< > & \" '"))).to eq("< > & \" '")
    end

    it "does not let the data change the font of the document" do
      # a font that does not exist used to raise and stop the PDF
      expect { printed(rendered("<font name=\"NaoExiste\">x</font>")) }
        .not_to raise_error
    end

    it "does not let the data add a link to the document" do
      rendered_data = rendered("<link href=\"http://evil.com\">x</link>")
      expect(printed(rendered_data))
        .to eq("<link href=\"http://evil.com\">x</link>")
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
      text = LiquidFormatter.new({ "d" => "Fulano <fulano@uff.br> tem CR < 7" })
        .format("{{ d }}", escape_data: :pdf)
      expect do
        helper.print_multipage_text_with_alignments(pdf, text, 500, 560)
      end.not_to raise_error
    end
  end

  describe "watermark_band" do
    # A4 in points, which is what new_document asks prawn for.
    let(:width) { 595.28 }
    let(:height) { 841.89 }
    let(:band_height) { 30 }
    let(:radians) { PdfHelper::WATERMARK_ANGLE * Math::PI / 180 }

    it "centers the band on the page" do
      band = helper.watermark_band(width, height, band_height)

      expect(band[:center]).to eq([width / 2, height / 2])
      expect(band[:left] + (band[:width] / 2)).to be_within(0.001)
        .of(width / 2)
      expect(band[:top] - (band[:height] / 2)).to be_within(0.001)
        .of(height / 2)
    end

    it "makes the band as long as the paper allows at the stamp angle" do
      band = helper.watermark_band(width, height, band_height)
      horizontal = band[:width] * Math.cos(radians).abs
      vertical = band[:width] * Math.sin(radians).abs
      margin = 2 * PdfHelper::WATERMARK_PAPER_MARGIN

      expect(horizontal).to be <= width - margin + 0.001
      expect(vertical).to be <= height - margin + 0.001
      # One of the two sides is what limits the band, so it reaches that side
      # instead of stopping short of the paper.
      expect(
        [horizontal / (width - margin), vertical / (height - margin)].max
      ).to be_within(0.001).of(1)
    end

    it "is limited by the width of the paper when the text lies flat" do
      band = helper.watermark_band(width, height, band_height, 0)

      expect(band[:width]).to be_within(0.001)
        .of(width - (2 * PdfHelper::WATERMARK_PAPER_MARGIN))
    end

    it "is limited by the height of the paper when the text stands upright" do
      band = helper.watermark_band(width, height, band_height, 90)

      expect(band[:width]).to be_within(0.001)
        .of(height - (2 * PdfHelper::WATERMARK_PAPER_MARGIN))
    end
  end

  describe "the watermark of a document" do
    # The watermark had no coverage and its placement was a pair of fixed
    # coordinates, so nothing noticed that the ink sat below and to the left of
    # the center of the paper. The position is only observable in the rendered
    # PDF, so these specs read the glyph positions back from it.
    def render_document(signature_type:, watermark: true, **options)
      helper.new_document(
        "watermark.pdf", "Boletim",
        watermark: watermark,
        pdf_config: ReportConfiguration.new(signature_type: signature_type),
        **options
      ) { |pdf| pdf.text "conteúdo do documento" }
    end

    # The phrase is rotated, so the extraction returns one run per glyph and it
    # cannot be matched as a string. Two things tell those glyphs apart from the
    # text of the document: each is a single character, and they are the runs
    # that the same document without the watermark does not have. The size of
    # the font does not tell them apart — the extraction reports it already
    # multiplied by the rotation.
    def single_character_runs(document)
      page = PDF::Reader.new(StringIO.new(document)).pages.first
      page.runs.filter_map do |run|
        next unless run.text.length == 1
        [run.text, run.x.round(2), run.y.round(2)]
      end
    end

    def watermark_glyphs(signature_type, **options)
      with_watermark = single_character_runs(
        render_document(signature_type: signature_type, **options)
      )
      without_watermark = single_character_runs(
        render_document(
          signature_type: signature_type, watermark: false, **options
        )
      )
      with_watermark - without_watermark
    end

    def watermark_center(signature_type, **options)
      glyphs = watermark_glyphs(signature_type, **options)
      expect(glyphs).not_to be_empty
      xs = glyphs.map { |(_, x, _)| x }
      ys = glyphs.map { |(_, _, y)| y }
      [(xs.min + xs.max) / 2.0, (ys.min + ys.max) / 2.0]
    end

    # A4, which is what new_document asks prawn for.
    let(:page_center) { [595.28 / 2, 841.89 / 2] }

    it "prints the watermark when the document asks for it" do
      expect(watermark_glyphs(:no_signature)).not_to be_empty
    end

    it "does not print it when the document does not ask for it" do
      document = render_document(
        signature_type: :no_signature, watermark: false
      )
      expect(single_character_runs(document)).to be_empty
    end

    it "centers the watermark on the paper" do
      # One glyph of tolerance: a run carries the origin of its glyph, not the
      # extent of the ink, so the box of the origins is short by about one
      # glyph in each direction.
      center = watermark_center(:no_signature)
      expect(center[0]).to be_within(20).of(page_center[0])
      expect(center[1]).to be_within(20).of(page_center[1])
    end

    it "centers it on paper that the phrase barely fits" do
      # Landscape A4 is the case where the phrase does not fit the paper at the
      # angle of the stamp, so the band shrinks it. What must not change is
      # where the ink sits.
      center = watermark_center(:no_signature, page_layout: :landscape)

      expect(center[0]).to be_within(20).of(page_center[1])
      expect(center[1]).to be_within(20).of(page_center[0])
    end

    it "keeps it in place when the signature footer changes the margins" do
      # The bottom margin grows to fit the signature footer, so a watermark
      # placed relative to the text box moves with it. The paper does not move.
      expect(watermark_center(:manual))
        .to eq(watermark_center(:no_signature))
    end
  end
end
