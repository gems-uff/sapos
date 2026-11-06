# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateEnablePanelVariable < ActiveRecord::Migration[7.0]
  def up
    CustomVariable.where(variable: "enable_panel").first ||
      CustomVariable.create(
        description: "Habilita o submenu de Painel na navegação (yes/no)",
        variable: "enable_panel",
        value: "no"
      )
  end

  def down
    CustomVariable.where(variable: "enable_panel").destroy_all
  end
end
