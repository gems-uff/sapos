# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Os credenciamentos que já existem ganham datas reconstruídas pelo paper_trail
# (AdvisementAuthorizationHistory). A saída lista o que a reconstrução não
# resolveu, para revisão depois do deploy.
class AddDatesToAdvisementAuthorizations < ActiveRecord::Migration[7.1]
  def up
    add_column :advisement_authorizations, :start_date, :date
    add_column :advisement_authorizations, :end_date, :date
    AdvisementAuthorization.reset_column_information

    history = AdvisementAuthorizationHistory.new.rebuild!
    say "Credenciamentos: #{history.inserted} períodos encerrados reconstruídos, " \
      "#{history.removed_duplicates.size} duplicatas fundidas, " \
      "#{history.skipped_periods} períodos de professor ou nível já apagado descartados"
    report "Versões do paper_trail ilegíveis, ignoradas", history.unreadable_version_ids
    report "Credenciamentos criados sem remoção registrada nem linha no banco", history.vanished_item_ids
    report "Matrículas desligadas sem orientador credenciado no nível na data do desligamento " \
      "-- revisar com a secretaria", history.dismissed_without_accredited_advisor
  end

  # Sem as datas, uma linha volta a significar credenciamento vigente: só fica
  # o período que vale hoje. As duplicatas fundidas não voltam.
  def down
    current = AdvisementAuthorization.on_date(Date.current).pluck(:id)
    AdvisementAuthorization.where.not(id: current).delete_all
    remove_column :advisement_authorizations, :end_date
    remove_column :advisement_authorizations, :start_date
  end

  private
    def report(title, ids)
      return if ids.empty?
      say "#{title} (#{ids.size}):"
      ids.each_slice(20) { |slice| say slice.join(", "), true }
    end
end
