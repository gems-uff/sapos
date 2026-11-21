# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# "Nao criar matricula" no mapeamento (issue #772): a view calcula se o edital
# configura algum dado de matricula, mas compara simbolos (nunca blank) e o
# resultado vai para uma variavel local que a caixa nao le.
RSpec.describe "Caixa Nao criar matricula no mapeamento", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.naocriar@ic.uff.br", "Adm")
  end

  def caixa(processo)
    inscricao = FactoryBot.create(:admission_application, admission_process: processo,
      name: "Cand", email: "cand_#{SecureRandom.hex(3)}@ic.uff.br")
    get map_student_admission_application_path(inscricao)
    Nokogiri::HTML(response.body).at_css('input[name="do_not_create_enrollment"]')
  end

  it "controle: edital com nivel e situacao abre com a caixa desmarcada" do
    processo = FactoryBot.create(:admission_process, level: FactoryBot.create(:level),
      enrollment_status: FactoryBot.create(:enrollment_status))
    expect(caixa(processo)["checked"]).to be_nil
  end

  it "edital sem nenhum dado de matricula abre com a caixa marcada", pending: "issue #772" do
    processo = FactoryBot.create(:admission_process, level: nil, enrollment_status: nil,
      admission_date: nil, enrollment_number_field: nil)
    expect(caixa(processo)["checked"]).to be_present
  end
end
