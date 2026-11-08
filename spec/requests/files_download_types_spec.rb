# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# FilesController#download devolve o arquivo gravado pelo formulario de
# candidatura. PDF e imagem abrem no navegador; o resto vai como download, com
# tipo generico, para que o navegador nunca interprete o conteudo como pagina.
# O envio ja recusa html e svg (FilledFormField::DEFAULT_FILE_EXTENSIONS), mas o
# que foi gravado antes continua no banco: por isso a gravacao aqui pula a
# validacao.
RSpec.describe "Download de arquivo enviado", type: :request do
  def envia(nome, conteudo, tipo)
    template = FactoryBot.create(:form_template)
    campo = FactoryBot.create(:form_field, form_template: template,
      field_type: Admissions::FormField::FILE)
    formulario = FactoryBot.create(:filled_form, form_template: template)
    caminho = Rails.root.join("tmp", "upload_#{SecureRandom.hex(6)}_#{nome}")
    File.binwrite(caminho, conteudo)
    preenchido = FactoryBot.build(:filled_form_field, filled_form: formulario,
      form_field: campo, value: nil, file: Rack::Test::UploadedFile.new(caminho, tipo, original_filename: nome.dup))
    preenchido.save!(validate: false)
    get "/files/#{preenchido.file.medium_hash}"
    expect(response).to have_http_status(:ok)
    expect(response.body.b).to eq(conteudo.b)
  ensure
    File.delete(caminho) if caminho && File.exist?(caminho)
  end

  it "abre imagem no navegador" do
    envia("foto.png", File.binread(Rails.root.join("spec", "fixtures", "user.png")), "image/png")

    expect(response.media_type).to eq("image/png")
    expect(response.headers["Content-Disposition"]).to start_with("inline")
  end

  it "abre PDF no navegador" do
    envia("documento.pdf", "%PDF-1.4\n%%EOF\n", "application/pdf")

    expect(response.media_type).to eq("application/pdf")
    expect(response.headers["Content-Disposition"]).to start_with("inline")
  end

  it "manda pagina HTML como download de tipo generico" do
    envia("pagina.html", "<html><script>1</script></html>", "text/html")

    expect(response.media_type).to eq("application/octet-stream")
    expect(response.headers["Content-Disposition"]).to start_with("attachment")
    expect(response.headers["Content-Disposition"]).to include("pagina.html")
  end

  it "manda SVG como download de tipo generico" do
    envia("desenho.svg", "<svg xmlns='http://www.w3.org/2000/svg'><script>1</script></svg>", "image/svg+xml")

    expect(response.media_type).to eq("application/octet-stream")
    expect(response.headers["Content-Disposition"]).to start_with("attachment")
  end
end
