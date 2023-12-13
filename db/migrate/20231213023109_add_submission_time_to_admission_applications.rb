# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddSubmissionTimeToAdmissionApplications < ActiveRecord::Migration[7.0]
  def up
    add_column :admission_applications, :submission_time, :datetime
    execute "
      UPDATE `admission_applications`
      SET `submission_time` = `updated_at`
      WHERE `filled_form_id` IN (
        SELECT `id`
        FROM `filled_forms`
        WHERE `is_filled` = \"1\"
      )
    "
  end

  def down
    remove_column :admission_applications, :submission_time
  end
end
