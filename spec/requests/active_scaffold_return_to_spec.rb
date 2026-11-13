# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O link "Fechar"/"Cancelar" das telas do active_scaffold usa o parametro
# return_to quando ele vem na URL. So endereco interno vale
# (config/initializers/active_scaffold_return_to.rb); o resto volta ao padrao.
RSpec.describe "Link de retorno das telas do active_scaffold", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_retorno@ic.uff.br", "Adm")
    @aluno = FactoryBot.create(:student)
  end

  def link_fechar(return_to)
    get student_path(@aluno), params: { return_to: return_to }
    expect(response).to have_http_status(:ok)
    Nokogiri::HTML(response.body).css("a.as_cancel").first&.attr("href")
  end

  it "usa o endereco interno pedido" do
    expect(link_fechar("/students?page=2")).to eq("/students?page=2")
  end

  it "ignora endereco javascript" do
    expect(link_fechar("javascript:alert(1)")).not_to start_with("javascript")
  end

  it "ignora endereco de outro site" do
    expect(link_fechar("https://exemplo.invalid/")).not_to include("exemplo.invalid")
  end
end
