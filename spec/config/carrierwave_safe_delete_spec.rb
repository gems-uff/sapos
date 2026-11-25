# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

# config/initializers/carrierwave_activerecord_safe_delete.rb: a linha de
# carrier_wave_files nao se apaga pela aplicacao.
RSpec.describe "Arquivo guardado nao se apaga pela aplicacao" do
  let(:tabela) { CarrierWave::Storage::ActiveRecord::ActiveRecordFile }

  before(:each) do
    @template = FactoryBot.create(:form_template)
    @campo = FactoryBot.create(
      :form_field, form_template: @template, field_type: Admissions::FormField::FILE
    )
    @dir = Dir.mktmpdir
  end

  after(:each) { FileUtils.remove_entry(@dir) }

  def envio(nome, conteudo)
    caminho = File.join(@dir, nome)
    File.binwrite(caminho, conteudo)
    Rack::Test::UploadedFile.new(caminho, "application/pdf")
  end

  def grava(nome, conteudo)
    filled_form = FactoryBot.create(:filled_form, form_template: @template)
    FactoryBot.create(
      :filled_form_field, filled_form: filled_form, form_field: @campo,
      value: nil, file: envio(nome, conteudo)
    )
  end

  def linha_antiga(hash = "#{SecureRandom.hex(16)}.pdf")
    linha = tabela.create!(
      medium_hash: hash, binary: "%PDF-1 sem dono", original_filename: "x.pdf",
      content_type: "application/pdf", size: 15
    )
    linha.update_column(:updated_at, 2.hours.ago)
    linha
  end

  describe "os fluxos do CarrierWave" do
    it "nao apaga o arquivo que outro campo usa ao excluir um campo" do
      primeiro = grava("primeiro.pdf", "%PDF-1 conteudo A")
      segundo = grava("segundo.pdf", "%PDF-1 conteudo A")

      primeiro.destroy!

      expect(Admissions::FilledFormField.find(segundo.id).file.read).to eq "%PDF-1 conteudo A"
    end

    # Ao desfazer uma gravacao, o after_rollback do CarrierWave chama remove!
    # no uploader de cada arquivo acrescentado nela (Mounter#remove_added).
    # Dentro do exemplo a transacao e aninhada e o rollback real nao acontece,
    # entao o exemplo chama o mesmo remove! diretamente.
    it "nao apaga o arquivo que outro campo usa quando o uploader e removido" do
      primeiro = grava("primeiro.pdf", "%PDF-1 conteudo A")
      segundo = grava("segundo.pdf", "%PDF-1 conteudo A")

      Admissions::FilledFormField.find(primeiro.id).file.remove!

      expect(Admissions::FilledFormField.find(segundo.id).file.read).to eq "%PDF-1 conteudo A"
    end

    # A foto da candidatura passa ao aluno pelo mesmo identificador
    # (Admissions::AdmissionApplication, sincronizacao do campo de aluno).
    it "nao apaga a foto da candidatura ao excluir o aluno que a recebeu" do
      campo = grava("foto.png", File.binread(Rails.root.join("spec", "fixtures", "user.png")))
      aluno = FactoryBot.create(:student)
      aluno.photo.retrieve_from_store!(campo.file_before_type_cast)
      aluno.save!
      expect(aluno.reload.photo_before_type_cast).to eq campo.file_before_type_cast

      aluno.destroy!

      expect(tabela.find_by(medium_hash: campo.file_before_type_cast)).to be_present
    end

    # Escrever na linha compartilhada dentro da gravacao do dono derruba, em
    # MariaDB, a gravacao simultanea de outro dono do mesmo arquivo.
    it "reaproveitar uma linha nao escreve nela" do
      primeiro = grava("primeiro.pdf", "%PDF-1 conteudo A")
      linha = tabela.find_by(medium_hash: primeiro.file_before_type_cast)
      linha.update_column(:updated_at, 2.hours.ago)

      grava("segundo.pdf", "%PDF-1 conteudo A")

      expect(linha.reload.updated_at).to be < 1.hour.ago
    end
  end

  describe "apagar a linha" do
    it "o model recusa" do
      linha = linha_antiga

      expect { linha.destroy }.to raise_error(CarrierWaveActiveRecordSafeDelete::Blocked)
      expect { linha.delete }.to raise_error(CarrierWaveActiveRecordSafeDelete::Blocked)
      expect(tabela.exists?(linha.id)).to be true
    end

    it "a limpeza em bloco da storage recusa" do
      linha_antiga

      expect { CarrierWave::Storage::ActiveRecord::File.delete_all }
        .to raise_error(CarrierWaveActiveRecordSafeDelete::Blocked)
      expect(tabela.count).to eq 1
    end
  end
end
