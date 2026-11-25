# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Os initializers que corrigem o active_scaffold e o recordselect redefinem
# metodos da gem por prepend. Metodo publico de controller e acao do Rails: se o
# initializer esquece o protected que a gem dava ao original, o metodo vira acao
# em todo controller que inclui o modulo, e basta uma rota generica para a URL
# alcanca-lo. Aqui se cobra que o initializer mantenha a visibilidade da gem: so
# e acao o que ja era acao no original, como o update_column da edicao em linha.
RSpec.describe "Metodos dos initializers nos controllers" do
  let(:initializers) { Rails.root.join("config/initializers").to_s }

  def controllers
    Rails.application.routes.routes
      .filter_map { |rota| rota.defaults[:controller] }.uniq
      .filter_map { |nome| "#{nome.camelize}Controller".safe_constantize }
  end

  # clear_action_methods!: a lista em cache pode trazer nome que outro exemplo
  # deixou (ver o exemplo do allow_any_instance_of abaixo).
  def acoes_de_initializer(classe)
    classe.clear_action_methods!
    classe.action_methods.select do |acao|
      classe.instance_method(acao).source_location&.first.to_s.start_with?(initializers)
    end
  end

  # Sem herdar (false): o prepend poe o modulo do initializer entre os
  # ancestrais do modulo da gem, e a busca herdada acharia a copia publica dele.
  def acao_no_original?(classe, acao)
    original = classe.instance_method(acao).super_method
    original.present? && original.owner.public_method_defined?(acao, false)
  end

  it "reconhece o update_column, que o initializer redefine e a gem ja expoe" do
    expect(acoes_de_initializer(StudentsController)).to include("update_column")
    expect(acao_no_original?(StudentsController, "update_column")).to be(true)
  end

  # O Rails guarda action_methods e so o refaz quando um metodo e criado, nao
  # quando e removido. O allow_any_instance_of cria um apelido publico no
  # controller e o tira no fim do exemplo: se uma requisicao montou a lista
  # nesse meio-tempo, o nome fica nela sem metodo por tras.
  it "ignora o que outro exemplo deixou na lista de acoes em cache" do
    allow_any_instance_of(ReportsController).to receive(:generate_qr_code_key).and_return("X")
    ReportsController.clear_action_methods!
    ReportsController.action_methods
    RSpec::Mocks.space.reset_all

    expect { acoes_de_initializer(ReportsController) }.not_to raise_error
  end

  it "nao torna acao metodo que a gem deixa protegido" do
    expostas = controllers.flat_map do |classe|
      acoes_de_initializer(classe).reject { |acao| acao_no_original?(classe, acao) }
    end
    expect(expostas.tally).to eq({})
  end
end
