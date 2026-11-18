# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Extensao do arquivo enviado num campo de arquivo da candidatura. Campo com
# lista configurada ("values") aceita so a lista dele; campo sem lista aceita
# documentos, imagens, audio, video e compactados
# (FilledFormField::DEFAULT_FILE_EXTENSIONS).
RSpec.describe Admissions::FilledFormField, "extensao do arquivo enviado", type: :model do
  def envio(nome, valores: nil)
    configuracao = valores ? JSON.dump("values" => valores) : nil
    template = FactoryBot.create(:form_template)
    campo = FactoryBot.create(:form_field, form_template: template,
      field_type: Admissions::FormField::FILE, configuration: configuracao)
    formulario = FactoryBot.create(:filled_form, form_template: template)
    caminho = Rails.root.join("tmp", "extensao_#{SecureRandom.hex(6)}_#{nome}")
    File.binwrite(caminho, "conteudo")
    preenchido = FactoryBot.build(:filled_form_field, filled_form: formulario, form_field: campo,
      value: nil, file: Rack::Test::UploadedFile.new(caminho, "application/octet-stream", original_filename: nome.dup))
    preenchido.valid?
    preenchido.errors[:value] + preenchido.errors[:base] + preenchido.errors[:file]
  ensure
    File.delete(caminho) if caminho && File.exist?(caminho)
  end

  describe "campo com lista configurada" do
    it "aceita a extensao da lista" do
      expect(envio("historico.pdf", valores: ["pdf"])).to be_empty
    end

    it "recusa extensao fora da lista, mesmo que a padrao a aceitasse" do
      expect(envio("historico.docx", valores: ["pdf"])).not_to be_empty
    end
  end

  describe "campo sem lista configurada" do
    %w[historico.pdf carta.docx carta.doc carta.odt texto.rtf notas.txt planilha.xlsx
       planilha.xls foto.jpg foto.JPEG foto.png foto.gif foto.webp foto.heic
       audio.mp3 audio.m4a audio.ogg audio.opus video.mp4 video.mov video.webm
       documentos.zip documentos.rar documentos.7z documentos.tar.gz documentos.tgz].each do |nome|
      it "aceita #{nome}" do
        expect(envio(nome)).to be_empty
      end
    end

    %w[pagina.html desenho.svg dados.xml script.js programa.exe impressao.ps semextensao].each do |nome|
      it "recusa #{nome}" do
        expect(envio(nome)).not_to be_empty
      end
    end
  end
end
