# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddUserToEnrollmentStatuses < ActiveRecord::Migration[6.0]
  def change
    add_column :enrollment_statuses, :user, :boolean
  end
end
