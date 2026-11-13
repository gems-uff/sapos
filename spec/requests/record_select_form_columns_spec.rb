# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Tres helpers trocam o campo de associacao do formulario pelo record_select
# (record_select_field), e nenhum exemplo abria esses formularios (#720). O
# helper chama API do recordselect dentro do form do active_scaffold, a mesma
# que muda quando qualquer um dos dois sobe de versao.
RSpec.describe "Campos record_select dos formularios", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_rs@ic.uff.br", "Adm"
    )
  end

  # Trecho do nome, em minusculas e sem a parte acentuada: casa igual em SQLite
  # e em MariaDB. Acento e outro assunto -- a collation do MariaDB ignora, o
  # SQLite nao --, e fica com a suite-mariadb e a homologacao.
  it "a busca acha o registro por um trecho do nome, sem diferenciar caixa" do
    FactoryBot.create(:course, name: "Introdução à Computação")

    get "/courses/browse", params: { search: "introdu" }, xhr: true,
      headers: { "HTTP_REFERER" => "http://www.example.com/course_research_areas/new" }

    expect(response.body).to include("Introdução à Computação")
  end

  # Navegador que nao envia Referer (configuracao, extensao de privacidade,
  # proxy) recebe 500 na busca de disciplina. O controle e o exemplo acima, que
  # manda o Referer da tela.
  it "a busca de disciplina responde sem Referer", pending: "issue #721" do
    FactoryBot.create(:course, name: "Introdução à Computação")

    get "/courses/browse", params: { search: "introdu" }, xhr: true

    expect(response).to have_http_status(:ok)
  end

  # O record_select_field gera um input de texto com a classe recordselect e
  # a URL de busca do controller da associacao; o hidden com o id e o
  # JavaScript do recordselect que cria, no navegador.
  def campo_record_select(html, associacao)
    Nokogiri::HTML(html).css("input.recordselect[name='record[#{associacao}]']").first
  end

  {
    "linha de pesquisa de curso" => [:new_course_research_area_path, {
      research_area: "/research_areas/browse", course: "/courses/browse"
    }],
    "membro de comissao" => [:new_admission_committee_member_path, {
      user: "/users/browse", admission_committee: "/admission_committees/browse"
    }],
    "comissao de fase" => [:new_admission_phase_committee_path, {
      admission_phase: "/admission_phases/browse",
      admission_committee: "/admission_committees/browse"
    }],
  }.each do |tela, (rota, campos)|
    describe tela do
      before(:each) do
        get send(rota)
        @tela = request.url
      end

      it "abre o formulario" do
        expect(response).to have_http_status(:ok)
      end

      campos.each do |associacao, busca|
        it "troca #{associacao} pelo record_select" do
          campo = campo_record_select(response.body, associacao)

          expect(campo).to be_present
          expect(campo["data-rs-type"]).to eq("Single")
          expect(campo["data-rs-url"]).to eq(busca)
        end

        # O navegador manda o referer da tela; o CoursesController decide por
        # ele se a busca vem do quadro de turmas, e sem referer responde 500.
        it "a busca de #{associacao} responde ao campo" do
          get busca, xhr: true, headers: { "HTTP_REFERER" => @tela }

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
