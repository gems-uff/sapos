# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Campo depois de Formacoes e antes do proximo Grupo (issue #763): a edicao do
# formulario o desenha acima do bloco de Formacoes.
RSpec.describe "Ordem dos campos em volta de Formacoes", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.ordem@ic.uff.br", "Adm")
  end

  let(:formacoes) do
    { field_type: Admissions::FormField::SCHOLARITY,
      configuration: { values: ["Graduacao"], statuses: ["Completo"] } }
  end

  def ordem(campos)
    get preview_form_template_path(create_admission_template("Ordem #{SecureRandom.hex(3)}", campos))
    corpo = response.body
    campos.keys.sort_by { |nome| corpo.index(nome) || Float::INFINITY }
  end

  it "controle: campo no Grupo seguinte fica depois das Formacoes" do
    campos = { "ZZAntes" => Admissions::FormField::STRING, "ZZFormacoes" => formacoes,
               "ZZGrupo" => Admissions::FormField::GROUP, "ZZNoGrupo" => Admissions::FormField::STRING }
    expect(ordem(campos)).to eq(campos.keys)
  end

  it "campo logo depois das Formacoes fica depois delas", pending: "issue #763" do
    campos = { "ZZAntes" => Admissions::FormField::STRING, "ZZFormacoes" => formacoes,
               "ZZDepois" => Admissions::FormField::STRING }
    expect(ordem(campos)).to eq(campos.keys)
  end
end
