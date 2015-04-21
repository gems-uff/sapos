# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddIndividualToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :individual, :boolean, default: true
  end
end
