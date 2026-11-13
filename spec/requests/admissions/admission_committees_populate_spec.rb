# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Os botoes do rodape de membros da comissao so tinham populate_authorized
# coberto (admission_committees_spec.rb). Sem cobertura (#720): quem cada um dos
# outros botoes -- professores, coordenacao, secretaria -- oferece.
#
# Como no spec vizinho, populate_members e trocado por um stub que captura os
# usuarios: a resposta real do populate_members.js.erb responde 500 hoje (o
# partial form_association_record e chamado com object:, e o do active_scaffold
# le a local record), e um exemplo verde ali prenderia o defeito.
RSpec.describe "Botoes de popular membros da comissao", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_coordenacao)], "coord.populate@ic.uff.br", "Coordenador Populate"
    )
    create_confirmed_user(
      [FactoryBot.create(:role_professor)], "prof.populate@ic.uff.br", "Professor Populate",
      professor: FactoryBot.create(:professor)
    )
    create_confirmed_user(
      [FactoryBot.create(:role_secretaria)], "sec.populate@ic.uff.br", "Secretaria Populate"
    )
    create_confirmed_user([], "sem.papel.populate@ic.uff.br", "Sem Papel Populate")

    @capturados = nil
    allow_any_instance_of(Admissions::AdmissionCommitteesController)
      .to receive(:populate_members) do |controller, users|
        @capturados = users.map(&:email)
        controller.head :ok
      end
  end

  it "populate_professors oferece so quem tem o papel de professor" do
    get populate_professors_admission_committees_path(format: :js), xhr: true

    expect(response).to have_http_status(:ok)
    expect(@capturados).to eq(["prof.populate@ic.uff.br"])
  end

  it "populate_coordination oferece so quem tem o papel de coordenacao" do
    get populate_coordination_admission_committees_path(format: :js), xhr: true

    expect(response).to have_http_status(:ok)
    expect(@capturados).to eq(["coord.populate@ic.uff.br"])
  end

  it "populate_secretary oferece so quem tem o papel de secretaria" do
    get populate_secretary_admission_committees_path(format: :js), xhr: true

    expect(response).to have_http_status(:ok)
    expect(@capturados).to eq(["sec.populate@ic.uff.br"])
  end

  it "na comissao existente a rota de membro chama o mesmo filtro" do
    comissao = FactoryBot.create(:admission_committee)

    get populate_secretary_admission_committee_path(comissao, format: :js), xhr: true

    expect(response).to have_http_status(:ok)
    expect(@capturados).to eq(["sec.populate@ic.uff.br"])
  end
end
