# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddCommitteeCanSeeOtherIndividualToAdmissionPhases < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_phases, :committee_can_see_other_individual, :boolean, null: false, default: false
  end
end
