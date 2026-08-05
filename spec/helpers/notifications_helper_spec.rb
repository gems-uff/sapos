# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe NotificationsHelper, type: :helper do
  describe "notification_body_preview" do
    it "keeps the line breaks of the body" do
      expect(helper.notification_body_preview("Turmas:\n- Alquimia")).to eq(
        "Turmas:<br />\n- Alquimia"
      )
    end

    it "keeps the indentation of the body" do
      expect(helper.notification_body_preview("a\n  b")).to eq(
        "a<br />\n&nbsp;&nbsp;b"
      )
    end

    it "keeps the markup of the template editor toolbar" do
      body = "<strong>a</strong> <em>b</em>"
      expect(helper.notification_body_preview(body)).to eq(body)
    end

    it "keeps the markup that the author of a template wrote" do
      body = "veja o <a href=\"http://uff.br\">SAPOS</a>"
      expect(helper.notification_body_preview(body)).to eq(body)
    end

    it "keeps the data that the formatter escaped" do
      body = LiquidFormatter.new({ "d" => "Fulano <fulano@uff.br>" })
        .format("{{ d }}", escape_data: :html)
      expect(helper.notification_body_preview(body)).to eq(
        "Fulano &lt;fulano@uff.br&gt;"
      )
    end

    it "renders the whitespace of the body as it is delivered" do
      body = "Prezado Fulano,\n\n<strong>Aviso</strong>\n  a  b"
      expect(helper.notification_body_preview(body)).to eq(
        Notifier.body_whitespace_to_html(body)
      )
    end

    # The preview is the only place where the body of a message reaches a
    # browser: a mail client does not run scripts and prawn does not even
    # understand them. Showing a message must not run what it carries.
    context "a body that carries a script" do
      it "does not run a script tag" do
        expect(helper.notification_body_preview("a<script>alert(1)</script>b"))
          .not_to include("<script>")
      end

      it "does not run an event handler" do
        body = "<div onmouseover=\"alert(1)\">passe aqui</div>"
        expect(helper.notification_body_preview(body))
          .not_to include("onmouseover")
      end

      it "does not run a javascript link" do
        body = "<a href=\"javascript:alert(1)\">clique</a>"
        expect(helper.notification_body_preview(body)).not_to include("javascript:")
      end

      it "does not run a script hidden in a style" do
        body = "<div style=\"background:url(javascript:alert(1))\">x</div>"
        expect(helper.notification_body_preview(body)).not_to include("javascript:")
      end

      it "keeps the alignment of the toolbar" do
        body = "<div style=\"text-align: center;\">Centralizado</div>"
        expect(helper.notification_body_preview(body)).to include("text-align")
        expect(helper.notification_body_preview(body)).to include("Centralizado")
      end

      it "does not let a body restyle the page around the preview" do
        body = "<style>body { display: none }</style>"
        expect(helper.notification_body_preview(body)).not_to include("<style")
      end

      it "does not embed another page in the preview" do
        body = "<iframe src=\"https://evil.com\"></iframe>"
        expect(helper.notification_body_preview(body)).not_to include("<iframe")
      end
    end

    # The preview exists to show what the recipient reads, so it keeps the
    # markup that a mail client renders, including the legacy markup that
    # email still relies on.
    context "the markup that a mail client renders" do
      {
        "an image" => "<img src=\"https://uff.br/logo.png\" alt=\"UFF\" width=\"80\">",
        "a font" => "<font color=\"#cc0000\" size=\"4\" face=\"Arial\">aviso</font>",
        "a heading" => "<h2>Aviso</h2>",
        "a rule" => "<hr>",
        "a quotation" => "<blockquote>texto citado</blockquote>",
        "a link that opens in another tab" =>
          "<a href=\"https://uff.br\" target=\"_blank\">SAPOS</a>",
        "a table with presentational attributes" =>
          "<table bgcolor=\"#eeeeee\"><tr><td valign=\"top\">a</td></tr></table>",
        "a list" => "<ul><li>Alquimia</li></ul>"
      }.each do |what, markup|
        it "keeps #{what}" do
          preview = helper.notification_body_preview(markup)
          tag = markup[/<([a-z0-9]+)/, 1]
          expect(preview).to include("<#{tag}")
        end
      end

      it "keeps the source of an image but not a script in it" do
        body = "<img src=\"javascript:alert(1)\">"
        expect(helper.notification_body_preview(body)).not_to include("javascript:")
      end

      it "drops an event handler of an image" do
        body = "<img src=\"https://uff.br/l.png\" onerror=\"alert(1)\">"
        preview = helper.notification_body_preview(body)
        expect(preview).to include("https://uff.br/l.png")
        expect(preview).not_to include("onerror")
      end
    end
  end
end
