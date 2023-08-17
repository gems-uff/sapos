# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a dismissal reason
class DismissalReason < ApplicationRecord
  has_paper_trail

  APPROVED = I18n.t(
    "activerecord.attributes.dismissal_reason.thesis_judgements.approved"
  )
  REPROVED = I18n.t(
    "activerecord.attributes.dismissal_reason.thesis_judgements.reproved"
  )
  INVALID = I18n.t(
    "activerecord.attributes.dismissal_reason.thesis_judgements.invalid"
  )

  THESIS_JUDGEMENT = [APPROVED, REPROVED, INVALID]

  validates :name, presence: true, uniqueness: true
  validates :thesis_judgement,
    presence: true, inclusion: { in: THESIS_JUDGEMENT }

  def to_label
    "#{self.name}"
  end
end
