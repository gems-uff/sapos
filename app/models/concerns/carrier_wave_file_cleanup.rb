# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Cleans up orphaned carrier_wave_files records when a mounted uploader column
# is updated or the owner record is destroyed.
#
# Including models must define `mount_uploader_name` returning the column symbol
# (e.g. :photo, :image).
module CarrierWaveFileCleanup
  extend ActiveSupport::Concern

  included do
    before_update :store_old_carrier_wave_hash
    after_update :cleanup_old_carrier_wave_file
    before_destroy :store_carrier_wave_hash_for_destroy
    after_destroy :cleanup_destroyed_carrier_wave_file
  end

  private
    def store_old_carrier_wave_hash
      col = mount_uploader_name.to_s
      if will_save_change_to_attribute?(col)
        @carrier_wave_hash_to_cleanup = attribute_in_database(col)
      end
    end

    def cleanup_old_carrier_wave_file
      return unless @carrier_wave_hash_to_cleanup
      self.class.delete_unreferenced_carrier_wave_file(@carrier_wave_hash_to_cleanup)
      @carrier_wave_hash_to_cleanup = nil
    end

    def store_carrier_wave_hash_for_destroy
      @carrier_wave_hash_for_destroy = read_attribute(mount_uploader_name)
    end

    def cleanup_destroyed_carrier_wave_file
      return unless @carrier_wave_hash_for_destroy
      self.class.delete_unreferenced_carrier_wave_file(@carrier_wave_hash_for_destroy)
    end

  module ClassMethods
    def delete_unreferenced_carrier_wave_file(hash)
      return if hash.blank?
      cw_file = CarrierWave::Storage::ActiveRecord::ActiveRecordFile.find_by(medium_hash: hash)
      return unless cw_file
      referenced = Student.where(photo: hash).exists? ||
                   ReportConfiguration.where(image: hash).exists? ||
                   Admissions::FilledFormField.where(file: hash).exists?
      cw_file.delete unless referenced
    end
  end
end
