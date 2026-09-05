# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Num controller namespaced, o `url_for` do Rails le `controller:` sem barra
# inicial como caminho relativo ao namespace. O active_scaffold e o record_select
# montam links a partir de `controller_path`, que vem absoluto mas sem a barra --
# entao um widget renderizado sob `Admissions::` e apontando para um controller de
# raiz gera rota inexistente e levanta UrlGenerationError. O
# `config/initializers/fix_url_for.rb` repete a chamada com a barra quando isso
# acontece.
#
# Os helpers que produzem esse arranjo hoje sao
# `Admissions::AdmissionCommitteeMembersHelper` e
# `Admissions::AdmissionPhaseCommitteesHelper`, que chamam `record_select_field`
# para `User` e `AdmissionCommittee`. Nenhum spec os renderiza, e por isso o
# contorno ficou sem rede: apagar o initializer nao produzia vermelho em lugar
# nenhum.
describe "url_for a partir de um controller namespaced" do
  def view_context_de(controller_class)
    controller = controller_class.new
    controller.request = ActionDispatch::TestRequest.create
    controller.request.path_parameters = {
      controller: controller_class.controller_path, action: "index"
    }
    controller.view_context
  end

  let(:view) { view_context_de(Admissions::AdmissionCommitteeMembersController) }

  it "alcanca controller de raiz, que e o caso do record_select de User" do
    expect(view.url_for(controller: "users", action: :browse)).to eq("/users/browse")
  end

  # Sem este exemplo o de cima passaria mesmo que o Rails deixasse de interpretar
  # `controller:` como relativo -- e ai ele estaria medindo outra coisa.
  it "a leitura relativa, que e a padrao, nao tem rota" do
    expect { view.url_for(controller: "admissions/users", action: :browse) }
      .to raise_error(ActionController::UrlGenerationError)
  end

  it "controller dentro do namespace continua resolvendo" do
    expect(view.url_for(controller: "admissions/admission_committees", action: :browse))
      .to eq("/admission_committees/browse")
  end
end
