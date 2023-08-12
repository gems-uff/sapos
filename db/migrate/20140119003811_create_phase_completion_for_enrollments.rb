# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreatePhaseCompletionForEnrollments < ActiveRecord::Migration[5.1]
  def up
    Enrollment.all.each do |enrollment|
      enrollment.save!
    end
  end

  def down
  end
end
