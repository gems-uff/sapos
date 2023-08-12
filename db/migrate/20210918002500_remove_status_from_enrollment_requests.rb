# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class RemoveStatusFromEnrollmentRequests < ActiveRecord::Migration[6.0]
  def change
    remove_column :enrollment_requests, :status
  end
end
