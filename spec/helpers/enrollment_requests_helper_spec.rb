# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe EnrollmentRequestsHelper, type: :helper do
  # A data do comentario era interpolada crua e dependia do formato global de
  # Time; com a retirada do monkey-patch (#625) ela passou a ser localizada
  # explicitamente. A regiao estava sem cobertura nenhuma.
  describe "enrollment_request_comments_show_column" do
    let(:enrollment_request) { FactoryBot.create(:enrollment_request) }

    it "renders an empty table when there is no comment" do
      html = helper.enrollment_request_comments_show_column(
        enrollment_request, nil
      )

      expect(html).to include("<tbody class=\"records\">")
      expect(html).not_to include("<tr class=")
    end

    # created_at e datetime: aqui a hora importa, e o formato e o
    # defaultdatetime (%d/%m/%Y %H:%M), nao o date_br das telas de data pura.
    it "formats the moment of the comment with the date and the time" do
      FactoryBot.create(
        :enrollment_request_comment, enrollment_request: enrollment_request,
        message: "faltou a ementa",
        created_at: Time.zone.local(2018, 3, 1, 14, 30)
      )
      html = helper.enrollment_request_comments_show_column(
        enrollment_request, nil
      )

      expect(html).to include("<td>01/03/2018 14:30</td>")
      expect(html).to include("faltou a ementa")
    end

    it "keeps the moment out of the long format of time" do
      FactoryBot.create(
        :enrollment_request_comment, enrollment_request: enrollment_request,
        created_at: Time.zone.local(2018, 3, 1, 14, 30)
      )
      html = helper.enrollment_request_comments_show_column(
        enrollment_request, nil
      )

      expect(html).not_to include("Março")
      expect(html).not_to include("2018-03-01")
    end

    it "renders one row per comment" do
      2.times do
        FactoryBot.create(
          :enrollment_request_comment, enrollment_request: enrollment_request,
          created_at: Time.zone.local(2018, 3, 1, 14, 30)
        )
      end
      html = helper.enrollment_request_comments_show_column(
        enrollment_request, nil
      )

      expect(html.scan("<tr class=").size).to eq 2
      expect(html).to include("even-record")
    end
  end
end
