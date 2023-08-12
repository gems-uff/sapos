# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class UpdateAllEndDateAndCancelDateOfScholarshipAndScholarshipDuration < ActiveRecord::Migration[5.1]
  def up
    Scholarship.all.each do |scholarship|
      scholarship.save!
    end
    ScholarshipDuration.all.each do |scholarship_duration|
      scholarship_duration.save!
    end
  end

  def down
  end
end
