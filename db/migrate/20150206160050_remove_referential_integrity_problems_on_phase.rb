# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class RemoveReferentialIntegrityProblemsOnPhase < ActiveRecord::Migration
  def up
  	PhaseCompletion.joins(:phase).where(Phase.arel_table[:name].eq(nil)).destroy_all
  end

  def down
  end
end
