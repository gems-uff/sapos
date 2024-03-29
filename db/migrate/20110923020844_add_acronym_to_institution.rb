# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddAcronymToInstitution < ActiveRecord::Migration[5.1]
  def self.up
    add_column :institutions, :code, :string
  end

  def self.down
    remove_column :institutions, :code
  end
end
