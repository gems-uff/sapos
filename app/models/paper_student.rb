# frozen_string_literal: true

class PaperStudent < ApplicationRecord
  include PaperAuthorshipGuardConcern

  has_paper_trail

  belongs_to :paper
  belongs_to :student

  def to_label
    "#{self.student.to_label} - #{self.paper.to_label}"
  end
end
