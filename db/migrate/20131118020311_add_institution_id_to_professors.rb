# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddInstitutionIdToProfessors < ActiveRecord::Migration[5.1]
  def change
    add_column :professors, :institution_id, :integer
    add_index :professors, :institution_id
  end
end
