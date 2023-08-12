# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddOriginalFilenameAndContentTypeAndSizeToCarrierWaveFiles < ActiveRecord::Migration[7.0]
  def up
    add_column :carrier_wave_files, :original_filename, :string
    add_column :carrier_wave_files, :content_type, :string
    add_column :carrier_wave_files, :size, :integer
    CarrierWave::Storage::ActiveRecord::ActiveRecordFile.find_each do |file|
      file.original_filename = file.medium_hash

      case file.medium_hash.split(".").last
      when "png"
        file.content_type = "image/png"
      when "jpg"
        file.content_type = "image/jpeg"
      when "jpeg"
        file.content_type = "image/jpeg"
      when "pdf"
        file.content_type = "application/pdf"
      else  # fallback to png
        file.content_type = "image/png"
      end

      file.size = file.binary.size
      file.save!
    end
    Student.find_each do |student|
      student.photo.recreate_versions! if student.photo?
    end
    ReportConfiguration.find_each do |report_configuration|
      report_configuration.image.recreate_versions! if report_configuration.image?
    end
  end

  def down
    remove_column :carrier_wave_files, :original_filename
    remove_column :carrier_wave_files, :content_type
    remove_column :carrier_wave_files, :size
  end
end
