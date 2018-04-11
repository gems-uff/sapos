# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddIdentityIssuingPlaceIdToStudents < ActiveRecord::Migration[5.1]
  def change
    add_column :students, :identity_issuing_place, :string
  end
end
