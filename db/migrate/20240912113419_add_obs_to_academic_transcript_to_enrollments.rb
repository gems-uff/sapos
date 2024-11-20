# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddObsToAcademicTranscriptToEnrollments < ActiveRecord::Migration[7.0]
  def up
    add_column :enrollments, :obs_to_academic_transcript, :text
  end
  def down
    remove_column :enrollments, :obs_to_academic_transcript
  end
end
