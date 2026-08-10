# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe Admissions::AdmissionProcessesHelper, type: :helper do
  # Colunas e titulo de PDF que imprimiam a data crua, contando com o
  # monkey-patch global de Date#to_s (#625).
  let(:admission_process) do
    FactoryBot.create(
      :admission_process,
      start_date: Date.new(2018, 3, 1), end_date: Date.new(2018, 6, 30)
    )
  end

  describe "edit_date_column" do
    it "formats the edit date in the brazilian format" do
      admission_process.update!(edit_date: Date.new(2018, 7, 15))
      expect(helper.edit_date_column(admission_process, nil)).to eq "15/07/2018"
    end

    # max_edit_date cai na data de fim quando nao ha data de edicao; este era o
    # ramo que a suite nunca executava.
    it "falls back to the end date when there is no edit date" do
      admission_process.update!(edit_date: nil)
      expect(helper.edit_date_column(admission_process, nil)).to eq "30/06/2018"
    end

    it "keeps the date out of the ISO format that Ruby uses by default" do
      admission_process.update!(edit_date: Date.new(2018, 7, 15))
      expect(helper.edit_date_column(admission_process, nil))
        .not_to include("2018-07-15")
    end
  end

  describe "admission_process_pdf_title" do
    it "formats the period of the process in the brazilian format" do
      title = helper.admission_process_pdf_title(admission_process).flatten.join

      expect(title).to include("01/03/2018")
      expect(title).to include("30/06/2018")
    end

    it "keeps the period out of the ISO format" do
      title = helper.admission_process_pdf_title(admission_process).flatten.join

      expect(title).not_to include("2018-03-01")
      expect(title).not_to include("2018-06-30")
    end
  end
end
