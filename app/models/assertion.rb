# frozen_string_literal: true

class Assertion < ApplicationRecord
  has_paper_trail

  belongs_to :enrollment, optional: false

  validates :name, presence: true

  def to_label
    "#{self.name}"
  end
end
