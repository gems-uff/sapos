# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Input de arquivo nao pode ser pre-preenchido pelo navegador: por seguranca,
# nenhuma pagina consegue dizer "este campo ja tem /caminho/arquivo.pdf". Entao
# um campo obrigatorio que JA tem arquivo salvo continua vazio para o HTML5 --
# e marcar required nele trava a submissao do formulario inteiro, para sempre,
# inclusive quando a pessoa so queria mudar outro campo.
#
# Pior: o active_scaffold renderiza o input escondido quando ha arquivo, e o
# navegador nao consegue focar elemento invisivel para mostrar o balao de
# validacao. O sintoma que chega ao usuario e "cliquei em salvar e nao aconteceu
# nada", sem mensagem nenhuma.
#
# A obrigatoriedade continua valendo no servidor (validate_file_field), que e
# onde ela pode ser verificada com o que esta gravado.
RSpec.describe "Admissions required file field", type: :request do
  before(:each) do
    @template = FactoryBot.create(:form_template, name: "Inscrição")
    @campo = FactoryBot.create(
      :form_field, form_template: @template, name: "Currículo",
      field_type: Admissions::FormField::FILE,
      configuration: { required: true }.to_json
    )
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2",
      simple_url: "mestrado-obrigatorio", form_template: @template,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
  end

  def com_arquivo
    filled_form = FactoryBot.create(
      :filled_form, form_template: @template, is_filled: true
    )
    FactoryBot.create(
      :filled_form_field, filled_form:, form_field: @campo, value: nil,
      file: Rack::Test::UploadedFile.new(
        Rails.root.join("spec", "fixtures", "user.png"), "image/png"
      )
    )
    FactoryBot.create(
      :admission_application, admission_process: @process, filled_form:
    )
  end

  def input_de(caminho)
    get caminho
    Nokogiri::HTML(response.body).at_css("input[type=file]")
  end

  def input_sem_arquivo
    input_de(new_admission_apply_path(admission_id: @process.simple_id))
  end

  def input_com_arquivo
    app = com_arquivo
    input_de(edit_admission_apply_path(
      admission_id: @process.simple_id, id: app.token
    ))
  end

  # Linha de base: sem arquivo, a obrigatoriedade tem de continuar valendo na
  # tela. Sem este exemplo, "nao e required" passaria por remover required de
  # todo mundo.
  it "keeps the field required while no file was sent" do
    expect(input_sem_arquivo["required"]).to be_present
  end

  it "renders the field of an application that already has a file" do
    expect(input_com_arquivo).to be_present
  end

  it "drops the browser requirement once a file is stored" do
    expect(input_com_arquivo["required"]).to be_nil
  end
end
