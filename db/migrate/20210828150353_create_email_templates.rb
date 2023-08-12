# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateEmailTemplates < ActiveRecord::Migration[6.0]
  def change
    create_table :email_templates do |t|
      t.string :name
      t.string :to
      t.string :subject
      t.text :body
      t.boolean :enabled, default: true

      t.timestamps
    end
  end
end
