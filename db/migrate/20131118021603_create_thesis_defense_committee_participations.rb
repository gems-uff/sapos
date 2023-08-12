# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateThesisDefenseCommitteeParticipations < ActiveRecord::Migration[5.1]
  def change
    create_table :thesis_defense_committee_participations do |t|
      t.references :professor
      t.references :enrollment

      t.timestamps
    end
  end
end
