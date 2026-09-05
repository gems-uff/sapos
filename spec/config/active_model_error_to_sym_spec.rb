# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O `keeping_errors` do active_scaffold preserva os erros do registro ao redor de
# um `save`. Ate a 3.6.0.pre ele iterava a colecao e reusava o item como nome de
# atributo (`old_errors[attr]`), o que funcionava enquanto o Rails entregava
# simbolos. No Rails 6.1 a colecao passou a entregar objetos `ActiveModel::Error`,
# que nao respondem a `to_sym`, e a tela quebrava com NoMethodError ao salvar pai
# com filho invalido. O projeto contornou dando `to_sym` ao objeto de erro.
#
# A gem passou a ramificar por API e nao pede mais `to_sym`. Estes exemplos fixam
# as duas metades disso: que a implementacao de hoje dispensa o metodo, e que a
# de entao precisava dele -- a segunda existe para que a primeira nao passe por
# acidente, caso `keeping_errors` deixe de percorrer o caminho que se quer medir.
describe "ActiveModel::Error e o keeping_errors do active_scaffold" do
  # Roda o bloco com `ActiveModel::Error#to_sym` ausente, restaurando depois o que
  # havia. Serve tanto com o monkey-patch no lugar quanto sem ele.
  def sem_to_sym
    definido = ActiveModel::Error.instance_methods(false).include?(:to_sym)
    original = ActiveModel::Error.instance_method(:to_sym) if definido
    ActiveModel::Error.send(:remove_method, :to_sym) if definido
    yield
  ensure
    ActiveModel::Error.send(:define_method, :to_sym, original) if definido
  end

  # Copia verbatim de active_scaffold 3.6.0.pre,
  # lib/active_scaffold/extensions/unsaved_record.rb, que e a versao em uso quando
  # o contorno foi escrito. Reproduzir de cabeca produziria uma versao que nunca
  # existiu; esta veio do proprio gem.
  module KeepingErrorsComoNa360Pre
    def keeping_errors_3_6_0_pre
      old_errors = errors.dup if errors.present?
      result = yield
      old_errors&.each do |attr|
        old_errors[attr].each { |msg| errors.add(attr, msg) unless errors.added?(attr, msg) }
      end
      result && old_errors.blank?
    end
  end

  let(:record) do
    Level.new.tap { |l| l.errors.add(:name, :blank) }
  end

  it "a implementacao de hoje preserva os erros sem pedir to_sym" do
    sem_to_sym do
      expect { record.keeping_errors { record.valid? } }.not_to raise_error
      expect(record.errors.attribute_names).to include(:name)
    end
  end

  it "a implementacao da 3.6.0.pre pedia to_sym, e sem ele quebrava" do
    record.extend(KeepingErrorsComoNa360Pre)
    sem_to_sym do
      expect { record.keeping_errors_3_6_0_pre { record.valid? } }
        .to raise_error(NoMethodError, /to_sym/)
    end
  end

  it "a colecao de erros entrega ActiveModel::Error, que e o que muda o ramo" do
    expect(record.errors.first).to be_a(ActiveModel::Error)
  end
end
