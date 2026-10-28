# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Decisao do mantenedor (#560, #597): o coletor e o UNICO ponto que apaga linha de
# carrier_wave_files. Trocar, remover ou destruir so zera a referencia.
#
# O armazenamento identifica o arquivo por MD5(conteudo).extensao, e bytes iguais
# compartilham a mesma linha -- inclusive entre modelos diferentes e com
# reports.carrierwave_file_id. Um ponto de escrita que apaga precisaria enxergar
# todas as referencias no instante da escrita; o coletor ja faz isso numa
# varredura so.
#
# O after_commit :remove_<coluna>!, on: :destroy que o mount_uploader instala
# apaga a linha sem olhar referencia nenhuma, e por isso entra aqui tambem.
RSpec.describe "Pontos de escrita preservam carrier_wave_files", type: :model do
  let(:ar_file) { CarrierWave::Storage::ActiveRecord::ActiveRecordFile }

  def upload(name, content)
    path = File.join(Dir.mktmpdir, name)
    File.binwrite(path, content)
    Rack::Test::UploadedFile.new(path, Rack::Mime.mime_type(File.extname(name)))
  end

  shared_examples "preserva a linha" do |column|
    let(:record) do
      build_owner.tap do |owner|
        owner.public_send("#{column}=", upload("original.png", "ORIGINAL-#{column}"))
        owner.save!
      end
    end
    let!(:hash) { record.read_attribute(column) }

    it "ao trocar o arquivo" do
      record.public_send("#{column}=", upload("novo.png", "NOVO-#{column}"))
      record.save!

      expect(ar_file.where(medium_hash: hash)).to exist
    end

    it "ao remover o arquivo" do
      record.public_send("remove_#{column}=", true)
      record.save!

      expect(ar_file.where(medium_hash: hash)).to exist
    end

    it "ao destruir o registro" do
      record.destroy!

      expect(ar_file.where(medium_hash: hash)).to exist
    end
  end

  describe Student do
    def build_owner = FactoryBot.build(:student)
    it_behaves_like "preserva a linha", :photo
  end

  describe ReportConfiguration do
    def build_owner = FactoryBot.build(:report_configuration, x: 0, y: 0, scale: 1)
    it_behaves_like "preserva a linha", :image
  end

  describe Admissions::FilledFormField do
    def build_owner = FactoryBot.build(:filled_form_field, value: nil)
    it_behaves_like "preserva a linha", :file
  end

  # FilledForm apaga os campos com dependent: :delete_all, sem callback por campo.
  it "preserva a linha ao destruir o formulario preenchido" do
    field = FactoryBot.create(:filled_form_field, value: nil, file: upload("anexo.pdf", "ANEXO"))
    hash = field.read_attribute(:file)

    field.filled_form.destroy!

    expect(ar_file.where(medium_hash: hash)).to exist
  end
end
