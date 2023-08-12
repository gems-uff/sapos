# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddSuporteRole < ActiveRecord::Migration[5.1]
  def self.up
    Role.create(
      id: 7,
      name: "Suporte",
      description: "Suporte (inserir fotos de alunos)"
    )
  end
end
