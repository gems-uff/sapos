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

    it "escapes the data of the body" do
      expect(helper.notification_body_preview("Fulano <fulano@uff.br>")).to eq(
        "Fulano &lt;fulano@uff.br&gt;"
      )
    end

    it "renders the same body that is delivered as html" do
      body = "Prezado <fulano@uff.br>,\n\n<strong>Aviso</strong>\n  a  b"
      expect(helper.notification_body_preview(body)).to eq(
        Notifier.body_whitespace_to_html(Notifier.escape_body(body))
      )
    end
  end
end
