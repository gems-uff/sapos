# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddIdentityIssuingPlaceToProfessors < ActiveRecord::Migration
  def change
    add_column :professors, :identity_issuing_place, :string
  end
end
