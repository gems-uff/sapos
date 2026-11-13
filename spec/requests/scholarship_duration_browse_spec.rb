# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O record_select de alocacoes de bolsa, usado no formulario de suspensao de
# bolsa, nunca era aberto (#720): o browse passa pelo record_select_includes do
# controller.
RSpec.describe "Browse de alocacoes de bolsa", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.bolsa.browse@ic.uff.br", "Adm")
  end

  it "lista cada alocacao pelo rotulo, com o id no item" do
    alocacao = FactoryBot.create(:scholarship_duration)

    get browse_scholarship_durations_path, xhr: true

    expect(response).to have_http_status(:ok)
    item = Nokogiri::HTML(response.body).at_css("li#rs#{alocacao.id}")
    expect(item.text.strip).to eq(alocacao.to_label)
  end

  # O exemplo acima e o controle: sem termo o browse responde. Com termo, a busca
  # de texto inteiro percorre as colunas de texto sem qualifica-las pela tabela,
  # e o record_select_includes junta enrollments e scholarships, que tambem tem
  # coluna obs: "ambiguous column name: obs" em SQLite, o mesmo em MariaDB.
  it "responde a busca com termo", pending: "issue #739" do
    FactoryBot.create(:scholarship_duration)

    get browse_scholarship_durations_path, params: { search: "a" }, xhr: true

    expect(response).to have_http_status(:ok)
  end
end
