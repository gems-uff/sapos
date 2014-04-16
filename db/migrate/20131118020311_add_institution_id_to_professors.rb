# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddInstitutionIdToProfessors < ActiveRecord::Migration
  def change
    add_column :professors, :institution_id, :integer
    add_index :professors, :institution_id
  end
end
