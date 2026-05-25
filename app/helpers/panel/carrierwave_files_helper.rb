# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Panel::CarrierwaveFilesHelper
  CARRIERWAVE_REFERENCES = [
    ["reports", "carrierwave_file_id", "id"],
    ["students", "photo", "medium_hash"],
    ["report_configurations", "image", "medium_hash"],
    ["filled_form_fields", "file", "medium_hash"]
  ].freeze

  def self.find_carrierwave_orphan_ids
    cw = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
    referenced_ids = CARRIERWAVE_REFERENCES.flat_map do |table, column, key|
      cw.joins("INNER JOIN #{table} ON #{table}.#{column} = carrier_wave_files.#{key}").pluck(:id)
    end
    cw.where.not(id: referenced_ids).pluck(:id)
  end

  def self.find_version_for_carrierwave_file(carrierwave_file, model_type: nil)
    medium_hash = carrierwave_file.medium_hash
    file_id = carrierwave_file.id

    return nil if medium_hash.blank? && file_id.blank?

    version = nil

    if model_type == "Report" || (model_type.nil? && file_id.present?)
      version = Version.where("object LIKE ?", "%carrierwave_file_id: #{file_id}%")
                       .where(item_type: "Report")
                       .order(created_at: :desc)
                       .first
    end

    if version.nil? && medium_hash.present?
      query = Version.where("object LIKE ?", "%#{medium_hash}%")
      query = query.where(item_type: model_type) if model_type.present?
      version = query.order(created_at: :desc).first
    end

    version
  end

  def size_column(record, column)
    number_to_human_size(record.size) if record.size.present?
  end

  def preview_show_column(record, column)
    return "-" if record.medium_hash.blank?

    if record.content_type.to_s.start_with?("image/")
      link_to(
        image_tag(download_path(record.medium_hash),
                  style: "max-width: 400px; max-height: 300px; object-fit: contain;"),
        download_path(record.medium_hash),
        target: "_blank"
      )
    else
      link_to I18n.t("panel.garbage_collector.download"),
              download_path(record.medium_hash),
              target: "_blank"
    end
  end

  def original_model_column(record, column)
    version = Panel::CarrierwaveFilesHelper.find_version_for_carrierwave_file(record)
    return "-" if version.blank?

    I18n.t("activerecord.models.#{version.item_type.underscore}.one", default: version.item_type)
  end
end
