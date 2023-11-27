# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionCommitteeMember < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_committee_members do |t|
      t.integer :admission_committee_id
      t.integer :user_id

      t.timestamps
    end
    add_index :admission_committee_members, :admission_committee_id
    add_index :admission_committee_members, :user_id
  end
end
