# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A matriz HTTP (spec/support/http_matrix.rb) roda por grupo de perfis e por
# menu, um arquivo cada. A rota só entra na matriz pelo menu do controller:
# controller novo sem menu sairia dela calado, e é aqui que ele aparece. O
# visitante e o desconhecido percorrem todas as rotas em
# spec/requests/route_authorization_spec.rb.
RSpec.describe "Matriz HTTP: menus" do
  let(:controllers) { RouteProbe.routes.map(&:controller).uniq }
  let(:listados) { HttpMatrix::MENUS.values.flatten }

  it "põe cada controller com rota em um menu" do
    sem_menu = controllers - listados
    expect(sem_menu).to be_empty,
      "controllers sem menu em HttpMatrix::MENUS (o da tela que os abre, ou fora_do_menu): #{sem_menu.join(', ')}"
  end

  it "não põe um controller em dois menus" do
    repetidos = listados.tally.select { |_, vezes| vezes > 1 }.keys
    expect(repetidos).to be_empty
  end

  it "não lista controller sem rota" do
    expect(listados - controllers).to be_empty
  end

  it "tem um arquivo por grupo de perfis e menu" do
    esperados = HttpMatrix::GRUPOS.keys.product(HttpMatrix::MENUS.keys).map do |grupo, menu|
      "#{grupo}/#{menu}_spec.rb"
    end
    pasta = Rails.root.join("spec/requests/matriz_http")
    existentes = Dir.glob("*/*_spec.rb", base: pasta)
    expect(existentes).to match_array(esperados)
  end
end
