# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateLetterRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :letter_requests do |t|
      t.integer :admission_application_id
      t.string :name
      t.string :email
      t.string :telephone
      t.string :access_token
      t.string :sent_email
      t.integer :filled_form_id

      t.timestamps
    end
    add_index :letter_requests, :admission_application_id
    add_index :letter_requests, :filled_form_id
  end
end
