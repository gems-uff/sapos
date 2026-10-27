# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# As datas de filiação eram datetime, e a migration que criou a tabela
# (20240524135850) as tirou de updated_at, com hora. O cast de datetime é
# leniente -- "31/02/2026" vira 03/03/2026 --, então o patch do date_picker não
# podia entregar o texto cru ao modelo, e o término que ele não entendia
# gravava filiação em aberto. A hora também fazia a linha antiga parecer
# alterada a cada envio do subform, e perto da meia-noite o dia em Ruby (fuso
# da aplicação) e o DATE() do on_date (UTC) discordavam.
#
# O dia é tomado no fuso da aplicação, em Ruby: um CAST no banco pegaria o dia
# em UTC. As colunas novas são preenchidas antes de as antigas saírem, para um
# erro no meio não levar as datas.
class ChangeAffiliationDatesToDate < ActiveRecord::Migration[7.1]
  # Sem o modelo da aplicação: nada de paper_trail nem validação, e os tipos
  # lidos são os do banco no momento.
  class Row < ActiveRecord::Base
    self.table_name = "affiliations"
  end

  def up
    replace_dates(:date) { |value| value&.to_date }
  end

  # A data vira meia-noite no fuso da aplicação; a hora antiga não volta.
  def down
    replace_dates(:datetime) { |value| value&.in_time_zone }
  end

  private
    def replace_dates(type)
      add_column :affiliations, :start_new, type
      add_column :affiliations, :end_new, type
      Row.reset_column_information
      Row.find_each do |row|
        row.update_columns(start_new: yield(row.start_date), end_new: yield(row.end_date))
      end

      remove_column :affiliations, :start_date
      remove_column :affiliations, :end_date
      rename_column :affiliations, :start_new, :start_date
      rename_column :affiliations, :end_new, :end_date
      Row.reset_column_information
    end
end
