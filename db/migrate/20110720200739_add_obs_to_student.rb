# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddObsToStudent < ActiveRecord::Migration[5.1]
  def self.up
    add_column :students, :obs, :text
  end

  def self.down
    remove_column :students, :obs
  end
end
