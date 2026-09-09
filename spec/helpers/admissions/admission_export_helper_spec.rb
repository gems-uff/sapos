# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "roo"

RSpec.describe Admissions::AdmissionExportHelper, type: :helper do
  # Reads edital.xlsx out of the zip binary and returns it opened with Roo.
  def open_edital_xlsx(zip_binary)
    xlsx_bytes = nil
    Zip::File.open_buffer(StringIO.new(zip_binary)) do |zip|
      xlsx_bytes = zip.get_entry("edital.xlsx").get_input_stream.read
    end
    tempfile = Tempfile.new(["edital", ".xlsx"])
    tempfile.binmode
    tempfile.write(xlsx_bytes)
    tempfile.close
    Roo::Excelx.new(tempfile.path)
  end

  it "builds the filename from year, semester and simple_url" do
    process = FactoryBot.build(
      :admission_process, year: 2024, semester: 1, simple_url: "mestrado"
    )
    expect(described_class.export_filename(process)).to eq("edital_2024_1_mestrado.zip")
  end

  it "exports a zip with one worksheet per table and a row per record" do
    process = FactoryBot.create(:admission_process)
    FactoryBot.create(:admission_application, admission_process: process, email: "a@e.com")
    FactoryBot.create(:admission_application, admission_process: process, email: "b@e.com")

    zip = described_class.export_zip(process)
    expect(zip[0, 2]).to eq("PK") # zip magic number

    xlsx = open_edital_xlsx(zip)
    expect(xlsx.sheets).to include(
      "meta", "admission_processes", "form_templates", "admission_applications"
    )

    xlsx.default_sheet = "admission_applications"
    expect(xlsx.last_row).to eq(3) # header + 2 applications

    xlsx.default_sheet = "admission_processes"
    expect(xlsx.row(1)).to include("level__name", "enrollment_status__name")
  end
end
