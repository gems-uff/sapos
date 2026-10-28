# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Decisao do mantenedor (#560, #597): o coletor e o unico ponto que apaga linha de
# carrier_wave_files, e apaga o que encontra sem dono, sem carencia. As
# versions do paper_trail nao contam como dono.
#
# A unica guarda e de 1 h sobre linhas recem-criadas: o PdfUploader grava a
# linha antes de o Report.create! apontar para ela (PdfHelper, fora de
# transacao), e uma varredura nesse intervalo apagaria o PDF em geracao.
RSpec.describe Panel::CarrierwaveFilesHelper, type: :helper do
  let(:ar_file) { CarrierWave::Storage::ActiveRecord::ActiveRecordFile }

  def stored_file(age: 2.hours)
    file = ar_file.create!(
      medium_hash: "#{SecureRandom.hex(16)}.pdf", original_filename: "a.pdf",
      content_type: "application/pdf", size: 3, binary: "pdf"
    )
    file.update_columns(created_at: age.ago, updated_at: age.ago)
    file
  end

  it "apaga a linha sem dono e devolve quantas apagou" do
    orphan = stored_file

    expect(described_class.run_mark_and_sweep!).to eq(1)
    expect(ar_file.where(id: orphan.id)).not_to exist
  end

  it "poupa a linha sem dono criada ha menos de 1 h" do
    recent = stored_file(age: 10.minutes)

    described_class.run_mark_and_sweep!

    expect(ar_file.where(id: recent.id)).to exist
  end

  it "apaga a linha citada so por uma version do paper_trail" do
    orphan = stored_file
    Version.create!(
      item_type: "Student", item_id: 1, event: "update",
      object: "---\nphoto: #{orphan.medium_hash}\n"
    )

    described_class.run_mark_and_sweep!

    expect(ar_file.where(id: orphan.id)).not_to exist
  end

  it "poupa a linha referenciada por report, aluno, configuracao de relatorio e anexo" do
    report_file = stored_file
    FactoryBot.create(:report, carrierwave_file: report_file)
    photo = stored_file
    FactoryBot.create(:student).update_column(:photo, photo.medium_hash)
    image = stored_file
    FactoryBot.create(:report_configuration, x: 0, y: 0, scale: 1).update_column(:image, image.medium_hash)
    attachment = stored_file
    FactoryBot.create(:filled_form_field).update_column(:file, attachment.medium_hash)

    described_class.run_mark_and_sweep!

    expect(ar_file.where(id: [report_file, photo, image, attachment].map(&:id)).count).to eq(4)
  end
end
