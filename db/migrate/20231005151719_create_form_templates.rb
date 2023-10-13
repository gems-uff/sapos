# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateFormTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :form_templates do |t|
      t.string :name
      t.string :description
      t.string :template_type
      t.timestamps
    end
  end
end
