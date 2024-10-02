# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents Configuration of a Report
class ReportConfiguration < ApplicationRecord
  has_paper_trail
  attr_accessor :preview

  validates :text, presence: true
  validates :order, presence: true
  validates :x, presence: true
  validates :y, presence: true
  validates :scale, presence: true
  validates :expiration_in_months, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :expiration_in_months_only_for_qr_code

  mount_uploader :image, ImageUploader

  enum signature_type: { no_signature: 0, manual: 1, qr_code: 2 }

  def initialize_dup(other)
    super
    attrib = other.attributes.except("id", "created_at", "updated_at")
    self.assign_attributes(attrib)
  end

  def mount_uploader_name
    :image
  end

  def signature_footer
    signature_type === "manual"
  end

  def qr_code_signature
    signature_type === "qr_code"
  end

  private
    def expiration_in_months_only_for_qr_code
      if expiration_in_months.present? && signature_type != "qr_code"
        errors.add(:expiration_in_months, :only_for_qr_code)
      end
    end
end
