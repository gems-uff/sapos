# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O record_select de pedidos de inscricao (formulario de comentario de pedido e
# filtro por pedido na busca de pedidos) declara search_on com :enrollment, que
# e associacao, nao coluna de enrollment_requests.
RSpec.describe "Busca de pedidos de inscricao pelo record_select", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.pedido.browse@ic.uff.br", "Adm")
    @pedido = FactoryBot.create(:enrollment_request, year: 2031, semester: 1)
    @outro = FactoryBot.create(:enrollment_request, year: 2032, semester: 2)
  end

  def itens
    Nokogiri::HTML(response.body).css("li.record").map { |li| li["id"] }
  end

  # Controle: sem termo o browse responde e lista os dois pedidos.
  it "lista os pedidos sem termo" do
    get "/enrollment_requests/browse", xhr: true

    expect(response).to have_http_status(:ok)
    expect(itens).to include("rs#{@pedido.id}", "rs#{@outro.id}")
  end

  # Com termo, o recordselect poe enrollment como nome de coluna no WHERE:
  # "no such column: enrollment" em SQLite, "Unknown column" em MariaDB.
  it "encontra o pedido pelo ano", pending: "issue #740" do
    get "/enrollment_requests/browse", params: { search: "2031" }, xhr: true

    expect(response).to have_http_status(:ok)
    expect(itens).to include("rs#{@pedido.id}")
    expect(itens).not_to include("rs#{@outro.id}")
  end
end
