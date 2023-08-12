# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateEnrollmentRequestComments < ActiveRecord::Migration[6.0]
  def change
    create_table :enrollment_request_comments do |t|
      t.text :message
      t.references :enrollment_request
      t.references :user

      t.timestamps
    end
  end
end
