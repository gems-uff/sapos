# frozen_string_literal: true

class Report < ApplicationRecord
  attr_accessor :identifier
  # relations
  belongs_to :user, foreign_key: "generated_by_id"
  belongs_to :carrierwave_file, foreign_key: "carrierwave_file_id", class_name: "CarrierWave::Storage::ActiveRecord::ActiveRecordFile"
end
