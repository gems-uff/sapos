# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class FixCustomVariableLog < ActiveRecord::Migration
  def up
    Version.where(:item_type => "Configuration").each do |v| 
      v.item_type = "CustomVariable"
      v.save
    end
  end

  def down
  end
end
