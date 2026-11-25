# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

# config/initializers/carrierwave_activerecord_no_overwrite.rb: a linha de
# carrier_wave_files ja guardada nunca e regravada por um envio novo.
RSpec.describe "Arquivo guardado reaproveitado pelo identificador" do
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

  # Dois conteudos diferentes com o mesmo resumo, so dentro do exemplo.
  def simula_mesmo_resumo(*conteudos)
    allow(Digest::MD5).to receive(:hexdigest).and_wrap_original do |original, texto|
      conteudos.include?(texto.to_s.b) ? "0" * 32 : original.call(texto)
    end
  end

  it "grava conteudo novo numa linha nova (controle)" do
    campo = grava("primeiro.pdf", "%PDF-1 conteudo A")

    linha = tabela.find_by(medium_hash: campo.file_before_type_cast)
    expect(linha.binary).to eq "%PDF-1 conteudo A"
    expect(linha.original_filename).to eq "primeiro.pdf"
  end

  it "reaproveita conteudo igual sem trocar o nome de quem gravou primeiro" do
    primeiro = grava("primeiro.pdf", "%PDF-1 conteudo A")

    expect { grava("segundo.pdf", "%PDF-1 conteudo A") }.not_to change(tabela, :count)

    linha = tabela.find_by(medium_hash: primeiro.file_before_type_cast)
    expect(linha.original_filename).to eq "primeiro.pdf"
  end

  it "recusa conteudo diferente com o mesmo identificador e deixa a linha intacta" do
    simula_mesmo_resumo("%PDF-1 conteudo A".b, "%PDF-1 conteudo B".b)
    primeiro = grava("primeiro.pdf", "%PDF-1 conteudo A")

    expect { grava("segundo.pdf", "%PDF-1 conteudo B") }
      .to raise_error(CarrierWaveActiveRecordNoOverwrite::ConflictingContent)

    expect(tabela.count).to eq 1
    linha = tabela.find_by(medium_hash: primeiro.file_before_type_cast)
    expect(linha.binary).to eq "%PDF-1 conteudo A"
    expect(linha.original_filename).to eq "primeiro.pdf"
  end

  it "recusa tambem pelo caminho sem model, o do documento gerado" do
    simula_mesmo_resumo("%PDF-1 conteudo A".b, "%PDF-1 conteudo B".b)
    grava("primeiro.pdf", "%PDF-1 conteudo A")

    expect {
      PdfUploader.new.store!(
        base64_contents: Base64.encode64("%PDF-1 conteudo B"), filename: "gerado.pdf"
      )
    }.to raise_error(CarrierWaveActiveRecordNoOverwrite::ConflictingContent)

    expect(tabela.sole.binary).to eq "%PDF-1 conteudo A"
  end
end
