# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddIsLanguageToPhases < ActiveRecord::Migration[5.1]
  def change
    add_column :phases, :is_language, :boolean, default: false
  end
end
