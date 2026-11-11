# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Golden-master das permissões — issue #742.
#
# O spec/models/ability_spec.rb verifica `can?` em amostras escolhidas, e não
# verifica `accessible_by`, que é o que o active_scaffold aplica à listagem de
# todo scaffold (beginning_of_chain) e às associações. Este arquivo completa
# aquele: em vez de amostras, a matriz inteira — cada papel × cada modelo ×
# cada ação, sobre a classe, sobre cada registro rotulado e pelo
# `accessible_by` — comparada com o baseline spec/goldens/ability_matrix.txt.
#
# Não afirma que as permissões estão CERTAS; afirma que continuam IGUAIS. É a
# guarda para upgrade do cancancan e do active_scaffold, e para mudança no
# Ability: toda diferença no baseline precisa de explicação antes do
# GOLDEN=overwrite.
#
# O conjunto de dados, que atravessa cada ramo de condição do Ability, está em
# spec/support/ability_dataset.rb e é o mesmo da matriz das rotas.
#
# ABILITY_MATRIX_SQL=<arquivo> grava também o SQL de cada accessible_by, para
# diagnosticar uma diferença; não entra no baseline. ABILITY_MATRIX_OUT=<arquivo>
# grava a matriz renderizada, para comparar duas versões noutro banco: em
# MariaDB a mensagem de erro do adaptador difere da do SQLite, e o que se
# compara lá é uma versão do cancancan contra a outra, não contra o baseline.
RSpec.describe "Matriz de permissões", type: :model do
  include GoldenMaster
  include ActiveSupport::Testing::TimeHelpers
  include AbilityDataset

  before(:each) { travel_to GoldenMaster::FROZEN_AT }
  after(:each) { travel_back }
  before(:each) { build_ability_dataset }

  # O Ability lê o lançamento de nota ao ser construído: cada perfil é vestido
  # na hora de construir o seu.
  def users_for_matrix
    AbilityDataset::PERFIS.to_h { |p| [p.first, -> { Ability.new(vestir_perfil(p)) }] }
  end

  it "mantém o baseline" do
    sql_path = ENV["ABILITY_MATRIX_SQL"]
    sql = sql_path ? +"" : nil
    matrix = AbilityMatrix.new(
      users: users_for_matrix, labels: @labels, extra_args: @extra_args, sql_dump: sql
    ).render
    File.write(sql_path, sql) if sql_path
    File.write(ENV["ABILITY_MATRIX_OUT"], matrix) if ENV["ABILITY_MATRIX_OUT"]

    expect_matches_golden("ability_matrix", matrix, format: :text)
  end

  # O baseline registra o can? e o accessible_by lado a lado, mas não cobra que
  # concordem. A listagem de cada scaffold é o accessible_by, e a abertura de
  # cada registro é o can?: se um deixa passar o que o outro nega, a tela lista
  # o que não abre, ou abre o que não lista. O cancancan traduz as mesmas
  # regras por dois caminhos (Ruby e SQL), e foi nessa tradução que os defeitos
  # das versões anteriores apareceram.
  it "lista pelo accessible_by exatamente o que o can? permite, registro a registro" do
    divergencias = []
    AbilityDataset::PERFIS.each do |perfil|
      ability = Ability.new(vestir_perfil(perfil))
      persistidos = @labels.select { |record, _| record.is_a?(ActiveRecord::Base) && record.persisted? }
      persistidos.group_by { |record, _| record.class }.each do |model, registros|
        AbilityMatrix::SQL_DUMP_ACTIONS.each do |acao|
          ids = model.unscoped.accessible_by(ability, acao).pluck(:id)
          registros.each do |registro, nome|
            pode = ability.can?(acao, registro)
            next if pode == ids.include?(registro.id)

            divergencias << "#{perfil.first} | #{model.name} | #{acao} | #{nome}: can? #{pode}, accessible_by #{!pode}"
          end
        end
      end
    end

    expect(divergencias).to be_empty, "can? e accessible_by discordam:\n#{divergencias.join("\n")}"
  end
end
