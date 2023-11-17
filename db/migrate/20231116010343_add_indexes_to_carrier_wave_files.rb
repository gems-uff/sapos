# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddIndexesToCarrierWaveFiles < ActiveRecord::Migration[7.0]
  def change
    add_index :carrier_wave_files, :medium_hash
    add_index :enrollments, :enrollment_number
    add_index :admission_applications, :token
    add_index :admission_processes, :simple_url
    add_index :students, :cpf
    add_index :professors, :cpf
  end
end
