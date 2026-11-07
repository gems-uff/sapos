# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O arquivo enviado pelo formulario de candidatura e gravado no banco pelo fork
# carrierwave-activerecord e devolvido por FilesController#download, a unica
# rota que o le de volta. Nenhum exemplo da suite passava por ela (#720): um
# update do carrierwave ou do fork (#672) que mudasse a gravacao ou a leitura
# chegaria verde. Estes exemplos prendem o ciclo inteiro -- grava pelo
# uploader, baixa pela rota publica, compara os bytes.
RSpec.describe "Files download", type: :request do
  let(:fixture) { Rails.root.join("spec", "fixtures", "user.png") }

  before(:each) do
    template = FactoryBot.create(:form_template)
    campo = FactoryBot.create(
      :form_field, form_template: template, field_type: Admissions::FormField::FILE
    )
    formulario = FactoryBot.create(:filled_form, form_template: template)
    @preenchido = FactoryBot.create(
      :filled_form_field, filled_form: formulario, form_field: campo, value: nil,
      file: Rack::Test::UploadedFile.new(fixture, "image/png")
    )
    @hash = @preenchido.file.medium_hash
  end

  it "devolve os mesmos bytes que foram enviados, sem pedir login" do
    get "/files/#{@hash}"

    expect(response).to have_http_status(:ok)
    expect(response.body.b).to eq(File.binread(fixture))
  end

  it "devolve o nome original, para exibir no navegador" do
    get "/files/#{@hash}"

    expect(response.headers["Content-Disposition"]).to start_with("inline")
    expect(response.headers["Content-Disposition"]).to include('filename="user.png"')
  end

  it "atende tambem pelo caminho antigo das candidaturas" do
    get "/admissions/files/#{@hash}"

    expect(response).to have_http_status(:ok)
    expect(response.body.b).to eq(File.binread(fixture))
  end

  it "aceita o hash pelo parametro antigo" do
    get "/files/qualquer", params: { hash: @hash }

    expect(response).to have_http_status(:ok)
    expect(response.body.b).to eq(File.binread(fixture))
  end

  it "responde nao encontrado para hash inexistente" do
    get "/files/naoexiste"

    expect(response).to have_http_status(:not_found)
  end

  it "monta a URL do campo pela mesma rota" do
    expect(@preenchido.file.url).to eq("/files/#{@hash}")
  end
end
