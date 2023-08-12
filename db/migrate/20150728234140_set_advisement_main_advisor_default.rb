# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class SetAdvisementMainAdvisorDefault < ActiveRecord::Migration[5.1]
  def change
    change_column :advisements, :main_advisor, :boolean, default: false
  end
end
