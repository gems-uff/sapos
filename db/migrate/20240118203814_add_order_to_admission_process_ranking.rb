# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddOrderToAdmissionProcessRanking < ActiveRecord::Migration[7.0]
  def up
    add_column :admission_process_rankings, :order, :integer
    Admissions::AdmissionProcess.joins(:rankings).distinct.each do |process|
      process.rankings.order(:id).each_with_index do |ranking, index|
        ranking.update(order: index + 1)
      end
    end
  end
  def down
    remove_column :admission_process_rankings, :order
  end
end
