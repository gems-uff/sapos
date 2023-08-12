# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddActionToClassEnrollmentRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :class_enrollment_requests, :action, :string, default: "Adição"
  end
end
