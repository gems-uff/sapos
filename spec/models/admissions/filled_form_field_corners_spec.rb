# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Cantos do campo preenchido sem cobertura (#720): arquivo acima do limite de
# 15 MB, erro cuja chave nao tem traducao propria do modelo, e as conversoes
# que engolem objeto sem to_s ou to_f.
RSpec.describe Admissions::FilledFormField, "cantos", type: :model do
  def png
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/user.png"), "image/png")
  end

  describe "arquivo acima de 15 MB" do
    it "descarta o arquivo e acusa o tamanho" do
      campo_de_arquivo = FactoryBot.create(:form_field, field_type: Admissions::FormField::FILE)
      preenchido = Admissions::FilledFormField.new(
        form_field: campo_de_arquivo, filled_form: FactoryBot.create(:filled_form), file: png
      )
      allow(preenchido.file.file).to receive(:size).and_return(16.megabytes)

      preenchido.valid?

      expect(preenchido.file).to be_blank
      expect(preenchido.errors[:file].join).to include(campo_de_arquivo.name)
      expect(preenchido.errors.details[:file]).to be_present
    end

    it "aceita o arquivo no limite" do
      campo_de_arquivo = FactoryBot.create(:form_field, field_type: Admissions::FormField::FILE)
      preenchido = Admissions::FilledFormField.new(
        form_field: campo_de_arquivo, filled_form: FactoryBot.create(:filled_form), file: png
      )
      allow(preenchido.file.file).to receive(:size).and_return(15.megabytes)

      preenchido.valid?

      expect(preenchido.file).to be_present
      expect(preenchido.errors[:file]).to be_empty
    end
  end

  describe "#add_error" do
    before(:each) do
      @preenchido = Admissions::FilledFormField.new(
        form_field: FactoryBot.create(:form_field, name: "Campo Erro", field_type: Admissions::FormField::STRING)
      )
    end

    it "cai na mensagem generica do Rails quando o modelo nao traduz a chave" do
      @preenchido.add_error(:blank)

      expect(@preenchido.errors[:value]).to eq(["Campo Erro #{I18n.t("errors.messages.blank")}"])
    end

    it "usa a mensagem dada quando nao ha traducao nenhuma" do
      @preenchido.add_error(:chave_inexistente_720, message: "mensagem propria")

      expect(@preenchido.errors[:value]).to eq(["Campo Erro mensagem propria"])
    end
  end

  describe "conversoes" do
    it "devolve nil para objeto sem to_s" do
      expect(Admissions::FilledFormField.convert_string(BasicObject.new)).to be_nil
    end

    it "devolve nil para objeto sem to_f" do
      expect(Admissions::FilledFormField.convert_number(Object.new)).to be_nil
    end
  end
end
