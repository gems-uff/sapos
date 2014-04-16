# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddIsLanguageToPhases < ActiveRecord::Migration
  def change
    add_column :phases, :is_language, :boolean, default: false
  end
end
