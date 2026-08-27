# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddDatesToAdvisementAuthorizations < ActiveRecord::Migration[7.1]
  def up
    add_column :advisement_authorizations, :start_date, :date
    add_column :advisement_authorizations, :end_date, :date

    # Credenciamentos que já existiam não têm data informada; a melhor
    # aproximação disponível é quando a linha entrou no banco. Todos ficam
    # ativos (end_date nula).
    execute(
      "UPDATE advisement_authorizations " \
      "SET start_date = created_at WHERE start_date IS NULL"
    )
  end

  def down
    remove_column :advisement_authorizations, :end_date
    remove_column :advisement_authorizations, :start_date
  end
end
