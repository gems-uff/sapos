# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true
class CreateActiveScaffoldWorkarounds < ActiveRecord::Migration[7.0]
  def change
    create_table :active_scaffold_workarounds do |t|
    end
  end
end
