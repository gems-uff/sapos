# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module PanelHelper
  CARRIERWAVE_REFERENCES = [
    ["reports", "carrierwave_file_id", "id"],
    ["students", "photo", "medium_hash"],
    ["report_configurations", "image", "medium_hash"],
    ["filled_form_fields", "file", "medium_hash"]
  ].freeze

  def find_carrierwave_orphans
    cw = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
    cw.where(id: find_carrierwave_orphan_ids)
  end

  def find_carrierwave_orphan_ids
    cw = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
    referenced_ids = CARRIERWAVE_REFERENCES.flat_map do |table, column, key|
      cw.joins("INNER JOIN #{table} ON #{table}.#{column} = carrier_wave_files.#{key}").pluck(:id)
    end
    cw.where.not(id: referenced_ids).pluck(:id)
  end

  def delete_carrierwave_orphans(ids)
    cw = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
    orphan_ids = find_carrierwave_orphan_ids
    valid_ids = ids.select { |id| orphan_ids.include?(id) }
    count = cw.where(id: valid_ids).destroy_all.count
    count
  end
end
