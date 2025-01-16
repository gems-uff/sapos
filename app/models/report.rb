# frozen_string_literal: true

class Report < ApplicationRecord
  attr_accessor :document_title, :document_body, :expiration_in_months
  belongs_to :user, foreign_key: "generated_by_id"
  belongs_to :invalidated_by, foreign_key: "invalidated_by_id", class_name: "User", optional: true
  belongs_to :carrierwave_file, foreign_key: "carrierwave_file_id", class_name: "CarrierWave::Storage::ActiveRecord::ActiveRecordFile", optional: true

  validates :file_name, presence: true

  def to_label
    "#{self.user.name} - #{I18n.l(self.created_at, format: '%d/%m/%Y %H:%M')}"
  end

  def invalidate!(user:)
    carrierwave_file = self.carrierwave_file
    self.update!(carrierwave_file_id: nil, invalidated_by: user, invalidated_at: Time.now)
    carrierwave_file.delete
  end

  def expires_at_or_invalid
    if self.invalidated_at.present?
      I18n.t("activerecord.attributes.report.invalidated")
    else
      self.expires_at.present? ? I18n.l(self.expires_at, format: "%d/%m/%Y") : nil
    end
  end
end
