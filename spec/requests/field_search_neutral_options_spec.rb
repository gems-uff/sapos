# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Um condition_for_<coluna>_column que nao filtra nada precisa devolver nil.
# O active_scaffold decide pelo nil se a coluna entrou no filtro; qualquer outro
# valor -- "" ou [] -- conta como filtro aplicado, mesmo sem virar SQL nenhum
# (apply_conditions descarta condicao em branco depois). O efeito e a lista se
# anunciar filtrada, com o link de remover filtro, sem filtro algum, e as
# colunas entrarem nos joins da busca a toa.
#
# Estas telas so tem cobertura de feature no caminho feliz, com a opcao
# preenchida; a opcao neutra -- que e o estado inicial de todo formulario de
# busca -- nao era exercitada em lugar nenhum.
RSpec.describe "Field search with neutral options", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "field_search_admin@ic.uff.br")
    sign_in @admin
  end

  def announces_filter?
    node = Nokogiri::HTML(response.body).at_css("div.filtered-message")
    raise "lista sem bloco de mensagem de filtro" if node.nil?
    node["style"].to_s.exclude?("display:none") ||
      node.at_css("div.reset").present?
  end

  # Cada entrada e um condition_for que devolve cedo quando o campo esta no
  # valor neutro. A chave e a coluna; o valor, o que o formulario de busca manda
  # quando o usuario nao mexeu nela.
  {
    "/enrollments" => {
      "scholarship_durations_active" => { scholarship_durations_active: "" },
      "active" => { active: "" },
      "accomplishments" => {
        accomplishments: { phase: "", year: "2024", month: "1", day: "1" }
      },
      "delayed_phase" => {
        delayed_phase: { phase: "", year: "2024", month: "1", day: "1" }
      },
      "enrollment_hold" => { enrollment_hold: { hold: "", active: "" } },
      "course_class_year_semester" => {
        course_class_year_semester: { year: "", semester: "", course: "" }
      }
    },
    "/enrollment_requests" => {
      "status" => { status: "" },
      "has_advisor" => { has_advisor: "" },
      "scholarship_durations_active" => { scholarship_durations_active: "" }
    },
    "/enrollment_holds" => {
      "active" => { active: "" }
    },
    # Aqui a opcao neutra nao e o vazio: o select oferece "Todas" com o valor
    # "all", que nao casa com nenhum ramo do case e cai no else.
    "/scholarship_durations" => {
      "active" => { active: "all" }
    },
    "/admission_applications" => {
      "is_filled" => { is_filled: "" },
      "pendency" => { pendency: "" },
      "status" => { status: "" },
      "mapping" => { mapping: "" }
    }
  }.each do |path, columns|
    describe "GET #{path}" do
      # Linha de base: sem parametro de busca a lista nao se anuncia filtrada.
      # Sem ela, um "not_to announce" nao prova nada.
      it "does not announce a filter when nothing was searched" do
        get path

        expect(response).to have_http_status(:ok)
        expect(announces_filter?).to be false
      end

      columns.each do |column, search|
        it "does not announce a filter when #{column} is left neutral" do
          get path, params: { search: search }

          expect(response).to have_http_status(:ok)
          expect(announces_filter?).to be false
        end
      end
    end
  end

  # O contraponto, em duas telas de mecanismos diferentes: preenchido de
  # verdade, a lista tem de se anunciar filtrada. Sem estes exemplos os
  # anteriores passariam tambem com um @filtered morto.
  it "announces a filter when an enrollments column is actually filled" do
    get enrollments_path, params: {
      search: { course_class_year_semester: {
        year: "2024", semester: "", course: ""
      } }
    }

    expect(response).to have_http_status(:ok)
    expect(announces_filter?).to be true
  end

  it "announces a filter when an enrollment holds column is actually filled" do
    get enrollment_holds_path, params: { search: { active: "1" } }

    expect(response).to have_http_status(:ok)
    expect(announces_filter?).to be true
  end
end
