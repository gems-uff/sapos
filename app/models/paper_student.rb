class PaperStudent < ApplicationRecord
  has_paper_trail

  belongs_to :paper
  belongs_to :student

  def to_label
    "#{self.student.to_label} - #{self.paper.to_label}"
  end
end
