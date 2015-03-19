# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreatePhaseCompletionForEnrollments < ActiveRecord::Migration
  def up
  	Enrollment.all.each do |enrollment|
  	  enrollment.save!
  	end
  end

  def down
  end
end
