# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# No subform de bolsas do formulario de matricula, escolher a bolsa dispara
# render_field (update_columns [:end_date], send_form_on_update_column) para
# preencher a data de fim a partir da admissao e do nivel ainda nao gravados.
# ScholarshipDurationsController#after_render_field faz params[:record].slice
# e atribui o resultado, que nao e permitido: ForbiddenAttributesError, 500.
RSpec.describe "Data de fim da alocacao de bolsa calculada no formulario", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.render.bolsa@ic.uff.br", "Adm")
    @nivel = FactoryBot.create(:level, default_duration: 24)
    @bolsa = FactoryBot.create(:scholarship, level: @nivel, end_date: Date.new(2030, 12, 31))
  end

  def escolher_bolsa(extra = {})
    post render_field_scholarship_durations_path, xhr: true, params: {
      column: "scholarship", value: @bolsa.id.to_s,
      record: {
        "admission_date(1i)" => "2024", "admission_date(2i)" => "3", "admission_date(3i)" => "1",
        "level" => @nivel.id.to_s,
      },
    }.merge(extra)
  end

  # Controle: fora do subform da matricula o ramo nao roda e o campo volta.
  it "responde ao escolher a bolsa na tela de alocacoes" do
    escolher_bolsa

    expect(response).to have_http_status(:ok)
  end

  it "responde ao escolher a bolsa no subform da matricula nova", pending: "issue #734" do
    escolher_bolsa(parent_controller: "enrollments", parent_id: "")

    expect(response).to have_http_status(:ok)
  end
end
