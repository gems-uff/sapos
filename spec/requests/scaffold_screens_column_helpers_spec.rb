# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Telas do active_scaffold que nenhum exemplo abria e cujo conteudo sai de um
# helper de coluna (#720): detalhe de desligamento, de modelo de e-mail, de
# notificacao e de aluno com foto; novo trancamento de bolsa; e a busca de
# curso pelo record_select.
RSpec.describe "Telas com helper de coluna", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_telas_colunas@ic.uff.br", "Adm"
    )
  end

  def html
    Nokogiri::HTML(response.body)
  end

  def coluna(nome)
    html.css("dd.#{nome}-view").first
  end

  it "o detalhe do desligamento mostra o nivel da matricula" do
    nivel = FactoryBot.create(:level, name: "Nivel do Desligamento")
    matricula = FactoryBot.create(:enrollment, level: nivel)
    desligamento = FactoryBot.create(:dismissal, enrollment: matricula)

    get dismissal_path(desligamento)

    expect(response).to have_http_status(:ok)
    expect(coluna("level").text.squish).to eq("Nivel do Desligamento")
  end

  # code_mirror_view_widget: o texto vai para o CodeMirror somente leitura
  # numa string JavaScript escapada, sem o setSize.
  describe "visualizacao do texto em CodeMirror" do
    def script_do_codemirror(id)
      html.css("div##{id} + script").first&.text
    end

    it "o detalhe do modelo de e-mail mostra o corpo" do
      modelo = FactoryBot.create(
        :email_template, name: "Modelo Detalhe", body: "Ola {{ nome }}\nl'aluno </script>"
      )

      get email_template_path(modelo)

      expect(response).to have_http_status(:ok)
      script = script_do_codemirror("body-view-#{modelo.id}")
      expect(script).to include("value: 'Ola {{ nome }}\\nl\\'aluno <\\/script>'")
      expect(script).to include("readOnly: true")
      expect(script).to include("lineWrapping: false")
      expect(script).not_to include("setSize")
    end

    it "o detalhe da notificacao mostra o corpo do template" do
      notificacao = FactoryBot.create(:notification, body_template: "Corpo da {{ notificacao }}")

      get notification_path(notificacao)

      expect(response).to have_http_status(:ok)
      script = script_do_codemirror("body_template-view-#{notificacao.id}")
      expect(script).to include("value: 'Corpo da {{ notificacao }}'")
      expect(script).to include("mode: 'liquid'")
    end
  end

  it "o detalhe do aluno com foto mostra a imagem pelo download" do
    aluno = FactoryBot.create(:student, name: "Aluno com Foto")
    aluno.update!(photo: Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/user.png"), "image/png"
    ))
    hash = aluno.reload.photo_before_type_cast

    get student_path(aluno)

    expect(response).to have_http_status(:ok)
    imagem = coluna("photo").css("img").first
    expect(imagem["src"]).to eq(download_path(hash))
    expect(imagem["style"]).to include("Object-fit: contain")
  end

  # Controle do anterior: sem foto, o helper devolve traco.
  it "o detalhe do aluno sem foto mostra traco" do
    aluno = FactoryBot.create(:student, name: "Aluno sem Foto")

    get student_path(aluno)

    expect(coluna("photo").text.squish).to eq("-")
  end

  it "o novo trancamento de bolsa usa mes e ano nas datas" do
    get new_scholarship_suspension_path

    expect(response).to have_http_status(:ok)
    %w[start_date end_date].each do |data|
      expect(html.css("select[name='record[#{data}(2i)]']")).not_to be_empty
      expect(html.css("select[name='record[#{data}(1i)]']")).not_to be_empty
      expect(html.css("select[name='record[#{data}(3i)]']")).to be_empty
    end
    expect(html.css("select.end_date-input")).not_to be_empty
  end

  it "a busca de curso pelo record_select acha o curso" do
    FactoryBot.create(:major, name: "Curso Buscado")

    get browse_majors_path, params: { search: "buscado" }, xhr: true

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Curso Buscado")
  end
end
