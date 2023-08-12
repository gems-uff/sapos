# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class FixCustomVariableLog < ActiveRecord::Migration[5.1]
  def up
    Version.where(item_type: "Configuration").each do |v|
      v.item_type = "CustomVariable"
      v.save
    end
  end

  def down
  end
end
