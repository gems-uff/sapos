# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

# config/initializers/carrierwave_activerecord_safe_delete.rb: a linha de
# carrier_wave_files so se apaga por destroy_unreferenced!, depois de conferir
# que nada aponta para ela.
RSpec.describe "Arquivo guardado so se apaga sem dono" do
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

    it "reaproveitar uma linha atualiza a data dela" do
      primeiro = grava("primeiro.pdf", "%PDF-1 conteudo A")
      linha = tabela.find_by(medium_hash: primeiro.file_before_type_cast)
      linha.update_column(:updated_at, 2.hours.ago)

      grava("segundo.pdf", "%PDF-1 conteudo A")

      expect(linha.reload.updated_at).to be > 1.minute.ago
    end
  end

  describe "apagar por fora do caminho seguro" do
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

  describe "#destroy_unreferenced!" do
    it "apaga a linha sem dono gravada ha mais de uma hora (controle)" do
      linha = linha_antiga

      expect(linha.destroy_unreferenced!).to be true
      expect(tabela.exists?(linha.id)).to be false
    end

    it "nao apaga a linha gravada ou reaproveitada ha menos do prazo" do
      linha = linha_antiga
      linha.touch

      expect(linha.destroy_unreferenced!).to be false
      expect(linha.destroy_unreferenced!(older_than: 0.seconds)).to be true
    end

    it "nao apaga a linha que um campo de formulario usa" do
      campo = grava("primeiro.pdf", "%PDF-1 conteudo A")
      linha = tabela.find_by(medium_hash: campo.file_before_type_cast)
      linha.update_column(:updated_at, 2.hours.ago)

      expect(linha.destroy_unreferenced!).to be false
      expect(tabela.exists?(linha.id)).to be true
    end

    it "nao apaga a foto de um aluno" do
      linha = linha_antiga("#{SecureRandom.hex(16)}.png")
      FactoryBot.create(:student).update_column(:photo, linha.medium_hash)

      expect(linha.destroy_unreferenced!).to be false
    end

    it "nao apaga a imagem de uma configuracao de relatorio" do
      linha = linha_antiga("#{SecureRandom.hex(16)}.png")
      FactoryBot.create(:report_configuration, scale: 1, x: 0, y: 0, image: nil)
        .update_column(:image, linha.medium_hash)

      expect(linha.destroy_unreferenced!).to be false
    end

    it "nao apaga o arquivo de um documento gerado" do
      linha = linha_antiga
      FactoryBot.create(:report, carrierwave_file: linha)

      expect(linha.destroy_unreferenced!).to be false
    end
  end

  # Coluna nova que guarde arquivo tem de entrar na lista, ou o caminho
  # seguro apagaria o arquivo dela.
  it "a lista de referencias cobre todo uploader montado e todo ponteiro para a tabela" do
    Rails.application.eager_load!
    modelos = ActiveRecord::Base.descendants.reject(&:abstract_class?)

    montados = modelos.flat_map { |m| m.uploaders.keys.map { |c| [m.name, c.to_sym] } }.uniq
    ponteiros = modelos.flat_map do |m|
      m.reflect_on_all_associations(:belongs_to).filter_map do |a|
        [m.name, a.foreign_key.to_sym] if a.options[:class_name] == tabela.name
      end
    end

    expect(montados).to match_array(CarrierWaveActiveRecordSafeDelete::REFERENCES_BY_HASH.to_a)
    expect(ponteiros).to eq [["Report", :carrierwave_file_id]]
  end
end
