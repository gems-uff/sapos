# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdvisementAuthorizations < ActiveRecord::Migration[5.1]
  def self.up
    create_table :advisement_authorizations do |t|
      t.integer :professor_id, references: :professors
      t.integer :level_id, references: :levels

      t.timestamps
    end
  end

  def self.down
    drop_table :advisement_authorizations
  end
end
