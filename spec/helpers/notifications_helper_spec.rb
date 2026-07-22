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
    end
  end
end
