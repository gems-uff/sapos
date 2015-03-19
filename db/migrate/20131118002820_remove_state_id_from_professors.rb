# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class RemoveStateIdFromProfessors < ActiveRecord::Migration
  def change
  	remove_column :professors, :state_id
  end
end
