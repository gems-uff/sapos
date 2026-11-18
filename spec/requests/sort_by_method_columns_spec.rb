# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Colunas da lista que o active_scaffold ordena por metodo do modelo
# (sort_by method:), e que nenhum exemplo ordenava (#720): ativo e
# coorientacao na lista de orientacoes, pontos de orientacao na de professores.
RSpec.describe "Ordenacao por coluna calculada", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_ordena@ic.uff.br", "Adm"
    )
    @nivel = FactoryBot.create(:level)
  end

  # Posicao de cada texto na pagina: a ordem das linhas da lista.
  def ordem(*textos)
    textos.sort_by { |texto| response.body.index(texto) || raise("#{texto} fora da lista") }
  end

  def orientacao(numero, professor)
    matricula = FactoryBot.create(:enrollment, enrollment_number: numero, level: @nivel)
    FactoryBot.create(:advisement, enrollment: matricula, professor: professor, main_advisor: true)
  end

  describe "lista de orientacoes" do
    before(:each) do
      @professor = FactoryBot.create(:professor)
      FactoryBot.create(:advisement_authorization, professor: @professor, level: @nivel, start_date: Date.new(2000, 1, 1))
    end

    it "ordena por ativo, pondo antes a orientacao de matricula desligada" do
      orientacao("M-ATIVA", @professor)
      desligada = orientacao("M-DESLIGADA", @professor)
      FactoryBot.create(:dismissal, enrollment: desligada.enrollment)

      get advisements_path, params: { sort: "active", sort_direction: "ASC" }
      expect(response).to have_http_status(:ok)
      expect(ordem("M-ATIVA", "M-DESLIGADA")).to eq(["M-DESLIGADA", "M-ATIVA"])

      get advisements_path, params: { sort: "active", sort_direction: "DESC" }
      expect(ordem("M-ATIVA", "M-DESLIGADA")).to eq(["M-ATIVA", "M-DESLIGADA"])
    end

    it "ordena por coorientacao, pondo depois a matricula que tem coorientador" do
      coorientada = orientacao("M-COORIENTADA", @professor)
      orientacao("M-SO-ORIENTADOR", @professor)
      coorientador = FactoryBot.create(:professor)
      FactoryBot.create(:advisement_authorization, professor: coorientador, level: @nivel, start_date: Date.new(2000, 1, 1))
      FactoryBot.create(:advisement, enrollment: Enrollment.find(coorientada.enrollment_id), professor: coorientador, main_advisor: false)

      get advisements_path, params: { sort: "co_advisor", sort_direction: "ASC" }

      expect(response).to have_http_status(:ok)
      expect(ordem("M-SO-ORIENTADOR", "M-COORIENTADA")).to eq(["M-SO-ORIENTADOR", "M-COORIENTADA"])
    end
  end

  it "ordena os professores pelos pontos de orientacao" do
    sem_pontos = FactoryBot.create(:professor, name: "Ana Sem Pontos")
    com_pontos = FactoryBot.create(:professor, name: "Zeca Com Pontos")
    [sem_pontos, com_pontos].each do |professor|
      FactoryBot.create(:advisement_authorization, professor: professor, level: @nivel, start_date: Date.new(2000, 1, 1))
    end
    orientacao("M-PONTO", com_pontos)

    get professors_path, params: { sort: "advisement_points", sort_direction: "DESC" }

    expect(response).to have_http_status(:ok)
    expect(ordem("Ana Sem Pontos", "Zeca Com Pontos")).to eq(["Zeca Com Pontos", "Ana Sem Pontos"])
  end
end
