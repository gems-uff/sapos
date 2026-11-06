# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admissions::AdmissionCommitteesController", type: :request do
  before(:each) do
    @role_coordenacao = FactoryBot.create(:role_coordenacao)
    @coordinator = create_confirmed_user(
      [@role_coordenacao], "coord.committee@ic.uff.br", "Coordenador"
    )
    sign_in @coordinator

    @level = FactoryBot.create(:level)

    # A query de populate_authorized junta User -> professor -> credenciamento;
    # o papel do usuário é irrelevante. Damos usuários sem papel (com papel de
    # professor, a validação exigiria um professor já associado no momento do
    # save) e ligamos o professor em seguida.
    current_user = create_confirmed_user(
      [], "vigente.committee@ic.uff.br", "OrientadorVigente"
    )
    current = FactoryBot.create(:professor, name: "OrientadorVigente", user: current_user)
    FactoryBot.create(:advisement_authorization, professor: current, level: @level,
                      start_date: Date.current - 1.day, end_date: nil)

    closed_user = create_confirmed_user(
      [], "encerrado.committee@ic.uff.br", "OrientadorEncerrado"
    )
    closed = FactoryBot.create(:professor, name: "OrientadorEncerrado", user: closed_user)
    FactoryBot.create(:advisement_authorization, professor: closed, level: @level,
                      start_date: Date.current - 2.days, end_date: Date.current - 1.day)
  end

  describe "GET populate_authorized" do
    # A lista de "orientadores credenciados" oferecida para a banca precisa
    # excluir quem foi descredenciado, casando com a mesma noção de vigência da
    # tela de matrícula (start_date iniciado e sem descredenciamento na data).
    #
    # Capturamos o conjunto que a ação monta em vez de asserir sobre o HTML: a
    # renderização do subform do active_scaffold depende de contexto que uma
    # requisição isolada não reproduz, mas o que este teste precisa provar é a
    # query com o filtro de vigência — que roda ao materializar `users`.
    it "offers only professors whose accreditation is current" do
      captured = nil
      allow_any_instance_of(Admissions::AdmissionCommitteesController)
        .to receive(:populate_members) do |controller, users|
          captured = users.to_a
          controller.head :ok
        end

      get "/admission_committees/populate_authorized.js"

      names = captured.map(&:name)
      expect(names).to include("OrientadorVigente")
      expect(names).not_to include("OrientadorEncerrado")
    end
  end
end
