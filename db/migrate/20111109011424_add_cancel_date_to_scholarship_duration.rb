# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddCancelDateToScholarshipDuration < ActiveRecord::Migration
  def self.up
    add_column :scholarship_durations, :cancel_date, :date
  end

  def self.down
    remove_column :scholarship_durations, :cancel_date
  end
end
