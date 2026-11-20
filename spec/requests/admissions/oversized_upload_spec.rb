# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# size_of_file muta o proprio registro dentro da validacao: alem de acrescentar o
# erro, faz self.file = nil. Como o erro depende do arquivo ainda estar ali, a
# segunda passada de validacao sobre o mesmo objeto nao encontra mais nada para
# reclamar e devolve valido.
#
# O caminho da candidatura faz exatamente duas passadas: assign_form chama
# self.valid? (admission_application.rb:476) e o apply_controller chama save em
# seguida (apply_controller.rb:52), que revalida pela cadeia de autosave. O
# resultado e a inscricao sendo aceita com o anexo descartado, sem que o
# candidato veja erro nenhum.
RSpec.describe "Admissions oversized upload", type: :request do
  before(:each) do
    @template = FactoryBot.create(:form_template, name: "Inscrição")
    @field = FactoryBot.create(
      :form_field, form_template: @template, name: "Currículo",
      field_type: Admissions::FormField::FILE, configuration: "{}"
    )
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2",
      simple_url: "mestrado-arquivo-grande", form_template: @template,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
  end

  def arquivo_de(bytes)
    tmp = Tempfile.new(["curriculo", ".pdf"])
    tmp.binmode
    tmp.write("0" * bytes)
    tmp.rewind
    Rack::Test::UploadedFile.new(tmp.path, "application/pdf")
  end

  def inscrever(arquivo)
    post admission_apply_index_path(admission_id: @process.simple_id), params: {
      commit: "Enviar inscrição",
      record: {
        name: "ZZ-TESTE Candidato", email: "zzteste@ic.uff.br",
        filled_form_attributes: {
          form_template_id: @template.id,
          enable_submission: "1",
          fields_attributes: {
            "0" => { form_field_id: @field.id, file: arquivo }
          }
        }
      }
    }
  end

  it "refuses a file above the configured limit" do
    CustomVariable.create!(variable: :max_upload_size_mb, value: "1")

    expect {
      inscrever(arquivo_de(2.megabytes))
    }.not_to change { Admissions::AdmissionApplication.count }
  end

  # Controle: dentro do limite a inscricao passa, com o arquivo preservado.
  # Sem ele, recusar toda inscricao com arquivo deixaria o exemplo acima verde.
  it "accepts a file within the configured limit" do
    CustomVariable.create!(variable: :max_upload_size_mb, value: "5")

    expect {
      inscrever(arquivo_de(1.megabyte))
    }.to change { Admissions::AdmissionApplication.count }.by(1)

    campo = Admissions::AdmissionApplication.last.filled_form.fields.first
    expect(campo.file).to be_present
  end
end
