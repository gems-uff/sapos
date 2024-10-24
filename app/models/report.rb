# frozen_string_literal: true

class Report < ApplicationRecord
  belongs_to :user, foreign_key: "generated_by_id"
  belongs_to :carrierwave_file, foreign_key: "carrierwave_file_id", class_name: "CarrierWave::Storage::ActiveRecord::ActiveRecordFile", optional: true

  def to_label
    "#{self.user.name} - #{I18n.l(self.created_at, format: '%d/%m/%Y %H:%M')}"
  end
end
