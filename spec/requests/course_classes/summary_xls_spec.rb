# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pauta da turma em planilha", type: :request do
  let(:turma) { FactoryBot.create(:course_class) }

  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "admin@ic.uff.br")
  end

  def xml_da_pauta
    get summary_xls_course_class_path(turma, format: :xlsx)
    Zip::File.open_buffer(StringIO.new(response.body)).read("xl/worksheets/sheet1.xml")
  end

  # Nome, e-mail e obs sao texto livre, e o nome pode vir do formulario de
  # inscricao. A pauta nao tem formula nenhuma: o que comeca com "=" tem de
  # chegar ao Excel como o texto que foi digitado.
  it "exporta como texto o conteudo que comeca com sinal de igual" do
    aluno = FactoryBot.create(:student, name: "=1+1")
    matricula = FactoryBot.create(:enrollment, student: aluno)
    FactoryBot.create(
      :class_enrollment, course_class: turma, enrollment: matricula,
      obs: "=2+2"
    )

    xml = xml_da_pauta

    expect(xml).not_to include("<f>")
    expect(xml).to include("=1+1").and include("=2+2")
  end
end
