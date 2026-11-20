# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Campo Arquivo com "Popular extensoes permitidas com SQL" (issue #758): a
# conferencia do servidor le so a lista fixa ("values") e ignora o SQL; e a
# lista esvaziada pela tela ([]) recusa todo arquivo.
RSpec.describe Admissions::FilledFormField, "extensoes do campo Arquivo por SQL", type: :model do
  def erros(nome, configuracao)
    template = FactoryBot.create(:form_template)
    campo = FactoryBot.create(:form_field, form_template: template,
      field_type: Admissions::FormField::FILE, configuration: JSON.dump(configuracao))
    formulario = FactoryBot.create(:filled_form, form_template: template)
    caminho = Rails.root.join("tmp", "extensao_sql_#{SecureRandom.hex(6)}_#{nome}")
    File.binwrite(caminho, "conteudo")
    preenchido = FactoryBot.build(:filled_form_field, filled_form: formulario, form_field: campo, value: nil,
      file: Rack::Test::UploadedFile.new(caminho, "application/octet-stream", original_filename: nome.dup))
    preenchido.valid?
    preenchido.errors.full_messages
  ensure
    File.delete(caminho) if caminho && File.exist?(caminho)
  end

  let(:so_pdf_por_sql) { { "values_use_sql" => true, "values_sql" => "SELECT 'pdf', 'pdf'" } }

  it "controle: a lista fixa recusa o que nao esta nela" do
    expect(erros("planilha.xlsx", { "values" => ["pdf"] })).not_to be_empty
    expect(erros("historico.pdf", { "values" => ["pdf"] })).to be_empty
  end

  it "recusa a extensao que o SQL nao devolve", pending: "issue #758" do
    expect(erros("planilha.xlsx", so_pdf_por_sql)).not_to be_empty
  end

  it "aceita a extensao que o SQL devolve, mesmo com lista fixa antiga guardada", pending: "issue #758" do
    expect(erros("historico.pdf", so_pdf_por_sql.merge("values" => ["docx"]))).to be_empty
  end

  it "lista esvaziada vale como lista nao configurada", pending: "issue #758" do
    expect(erros("historico.pdf", { "values" => [] })).to be_empty
  end
end
