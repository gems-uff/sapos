# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  # date_br e o ponto unico por onde passa a formatacao de data das telas, no
  # lugar do antigo monkey-patch global de Date#to_s (#625). O patch quebrou
  # sozinho num upgrade de Rails sem que nada acusasse, justamente porque nenhum
  # spec o exercitava; estes exemplos existem para que o sucessor nao repita
  # isso.
  describe "date_br" do
    it "formats a date in the brazilian format" do
      expect(helper.date_br(Date.new(2018, 3, 1))).to eq "01/03/2018"
    end

    it "pads the day and the month with a zero" do
      expect(helper.date_br(Date.new(2026, 8, 8))).to eq "08/08/2026"
    end

    # O I18n escolhe o formato pela classe do argumento, e time.formats.default
    # e o formato longo por extenso. Sem o to_date interno, uma coluna datetime
    # -- affiliations.start_date, por exemplo -- sairia como
    # "Quinta, 01 de Março de 2018, 14:30 h".
    it "formats a Time as a date, not as the long format of time" do
      expect(helper.date_br(Time.new(2018, 3, 1, 14, 30))).to eq "01/03/2018"
    end

    it "formats a DateTime as a date" do
      expect(helper.date_br(DateTime.new(2018, 3, 1, 14, 30))).to eq "01/03/2018"
    end

    it "formats a zoned time as a date" do
      expect(helper.date_br(Time.zone.local(2018, 3, 1, 14, 30))).to eq "01/03/2018"
    end

    it "falls back to the blank text when there is no date" do
      expect(helper.date_br(nil)).to eq I18n.t("rescue_blank_text")
    end

    it "accepts a blank text of its own" do
      expect(helper.date_br(nil, blank_text: "-")).to eq "-"
    end

    it "agrees with the locale file, which is the single source of the format" do
      date = Date.new(2018, 3, 1)
      expect(helper.date_br(date)).to eq(
        date.strftime(I18n.t("date.formats.default"))
      )
    end
  end
end
