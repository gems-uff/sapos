# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddReferenceCounterToCarrierWaveFile < ActiveRecord::Migration[5.1]
  def change
    add_column :carrier_wave_files, :reference_counter, :integer, default: 0
    execute "
      update carrier_wave_files
      set reference_counter = (
        (
          select count(*)
          from students
          where students.photo in (
            select t1.medium_hash
            from (select medium_hash from carrier_wave_files) as t1
            where lower(t1.medium_hash) = lower(carrier_wave_files.medium_hash)
          )
        ) + (
          select count(*)
          from report_configurations
          where report_configurations.image in (
            select t1.medium_hash
            from (select medium_hash from carrier_wave_files) as t1
            where lower(t1.medium_hash) = lower(carrier_wave_files.medium_hash)
          )
        )
      )
      where (carrier_wave_files.medium_hash IS NOT NULL)"
  end
end
