# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O active_scaffold guarda filtro, ordenacao e pagina em
# `active_scaffold_session_storage`, que faz `session[chave] ||= {}` -- escrita
# no topo apenas na primeira vez -- e deixa os chamadores mutarem o hash
# devolvido. O activerecord-session_store so grava a linha quando o registro
# parece sujo, e a comparacao que ele faz (`record.data = session_data`) tem os
# mesmos objetos dos dois lados: mutacao em lugar muda os dois de uma vez e
# passa despercebida.
#
# O efeito era a linha congelar no estado da primeira requisicao. Os specs de
# feature cobrem o que o usuario ve; estes cobrem o mecanismo, sem navegador, e
# e neles que a causa fica presa. Ver
# config/initializers/fix_session_store_dirty_tracking.rb.
RSpec.describe "sessao do active_scaffold", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_sessao@ic.uff.br", "Adm", "A1b2c3d4!"
    )
    course_type = FactoryBot.create(:course_type)
    16.times do |i|
      FactoryBot.create(:course, name: "Turma A #{i}", code: "TA#{i}", course_type: course_type)
      FactoryBot.create(:course, name: "Turma B #{i}", code: "TB#{i}", course_type: course_type)
    end
  end

  def search(name)
    get courses_path, params: { search: { name: name } }, xhr: true
  end

  def listed_names
    response.body.scan(/Turma [AB] \d+/).uniq
  end

  def stored_search
    ActiveRecord::SessionStore::Session.last.reload.data.dig("as:courses", "search")
  end

  it "grava na linha da sessao a busca que troca, nao so a primeira" do
    search "Turma A"
    expect(stored_search).to eq("name" => "Turma A")

    search "Turma B"
    expect(stored_search).to eq("name" => "Turma B")
  end

  it "pagina sob o filtro novo depois de trocar o filtro" do
    search "Turma A"
    search "Turma B"

    get courses_path, params: { page: 2 }, xhr: true

    expect(listed_names).to all(include("Turma B"))
    expect(listed_names).not_to be_empty
  end

  # A correcao devolve sentido a comparacao em vez de marcar o registro sujo
  # sempre; e o que a distingue de gravar a linha a cada requisicao. Este
  # exemplo prende essa diferenca: a primeira ida a pagina 2 guarda a pagina, a
  # segunda, identica, nao tem o que guardar.
  it "nao regrava a linha quando a requisicao nao mexe na sessao" do
    search "Turma A"
    get courses_path, params: { page: 2 }, xhr: true

    row = ActiveRecord::SessionStore::Session.last
    before = row.reload.updated_at
    get courses_path, params: { page: 2 }, xhr: true

    expect(row.reload.updated_at).to eq before
  end
end
